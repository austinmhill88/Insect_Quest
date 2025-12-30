import 'package:flutter/material.dart';
import '../models/trade.dart';
import '../models/capture.dart';
import '../services/firestore_service.dart';
import '../services/user_service.dart';
import 'journal_page.dart';
import 'package:uuid/uuid.dart';

class TradingPage extends StatefulWidget {
  const TradingPage({super.key});

  @override
  State<TradingPage> createState() => _TradingPageState();
}

class _TradingPageState extends State<TradingPage> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Trade> _availableTrades = [];
  List<Trade> _myTrades = [];
  bool _loading = true;
  String? _error;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadTrades();
  }

  Future<void> _loadTrades() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final userId = await UserService.getUserId();
      final available = await _firestoreService.listAvailableTrades();
      final myTrades = await _firestoreService.getUserTrades(userId);
      setState(() {
        _availableTrades = available;
        _myTrades = myTrades;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _createTrade() async {
    final captures = await JournalPage.loadCaptures();
    if (captures.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You need to capture an insect first!')),
        );
      }
      return;
    }

    final userId = await UserService.getUserId();
    Capture? selectedCapture;
    int coinsOffered = 0;
    int coinsRequested = 0;

    if (mounted) {
      await showDialog(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Create Trade Listing'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Select a card to offer:'),
                      const SizedBox(height: 8),
                      DropdownButton<Capture>(
                        isExpanded: true,
                        value: selectedCapture,
                        hint: const Text('Choose a capture'),
                        items: captures.map((capture) {
                          return DropdownMenuItem<Capture>(
                            value: capture,
                            child: Text('${capture.species ?? capture.genus} (${capture.tier})'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedCapture = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Coins to offer (optional)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          coinsOffered = int.tryParse(value) ?? 0;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Coins requested (optional)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          coinsRequested = int.tryParse(value) ?? 0;
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (selectedCapture == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select a capture')),
                        );
                        return;
                      }

                      final trade = Trade(
                        id: '', // Firestore will generate the ID
                        offeredCaptureId: selectedCapture!.id,
                        offeredByUserId: userId,
                        coinsOffered: coinsOffered,
                        coinsRequested: coinsRequested,
                        status: TradeStatus.listed,
                        createdAt: DateTime.now(),
                      );

                      try {
                        await _firestoreService.createTrade(trade);
                        Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Trade listed successfully!')),
                          );
                        }
                        await _loadTrades();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('List'),
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }

  Future<void> _acceptTrade(Trade trade) async {
    final userId = await UserService.getUserId();
    if (trade.offeredByUserId == userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot accept your own trade')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accept Trade'),
        content: Text(
          'Accept this trade?\n\n'
          'You will pay: ${trade.coinsRequested} coins\n'
          'You will receive: ${trade.coinsOffered} coins\n'
          '\nCoins will be held in escrow until trade is completed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestoreService.acceptTrade(trade.id, userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trade accepted! Coins in escrow.')),
          );
        }
        await _loadTrades();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _cancelTrade(Trade trade) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Trade'),
        content: const Text('Are you sure you want to cancel this trade?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestoreService.cancelTrade(trade.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trade cancelled')),
          );
        }
        await _loadTrades();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Widget _buildTradeCard(Trade trade, {bool isMyTrade = false}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  trade.status == TradeStatus.listed
                      ? Icons.shopping_bag
                      : trade.status == TradeStatus.pending
                          ? Icons.hourglass_empty
                          : trade.status == TradeStatus.completed
                              ? Icons.check_circle
                              : Icons.cancel,
                  color: trade.status == TradeStatus.listed
                      ? Colors.green
                      : trade.status == TradeStatus.pending
                          ? Colors.orange
                          : trade.status == TradeStatus.completed
                              ? Colors.blue
                              : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Card ID: ${trade.offeredCaptureId.substring(0, 8)}...',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Chip(
                  label: Text(trade.status.name.toUpperCase()),
                  backgroundColor: trade.status == TradeStatus.listed
                      ? Colors.green[100]
                      : trade.status == TradeStatus.pending
                          ? Colors.orange[100]
                          : trade.status == TradeStatus.completed
                              ? Colors.blue[100]
                              : Colors.red[100],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text('Offering: ${trade.coinsOffered} coins'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.blue, size: 20),
                const SizedBox(width: 4),
                Text('Requesting: ${trade.coinsRequested} coins'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Listed: ${trade.createdAt.toLocal().toString().split('.')[0]}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (trade.acceptedAt != null)
              Text(
                'Accepted: ${trade.acceptedAt!.toLocal().toString().split('.')[0]}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isMyTrade && trade.status == TradeStatus.listed)
                  TextButton.icon(
                    onPressed: () => _cancelTrade(trade),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
                  ),
                if (!isMyTrade && trade.status == TradeStatus.listed)
                  ElevatedButton.icon(
                    onPressed: () => _acceptTrade(trade),
                    icon: const Icon(Icons.check),
                    label: const Text('Accept'),
                  ),
                if (trade.status == TradeStatus.pending)
                  const Text(
                    '⏳ In Escrow',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Trading'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadTrades,
            ),
          ],
          bottom: TabBar(
            onTap: (index) {
              setState(() {
                _selectedTab = index;
              });
            },
            tabs: const [
              Tab(text: 'Available'),
              Tab(text: 'My Trades'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: $_error'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadTrades,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadTrades,
                    child: _selectedTab == 0
                        ? _availableTrades.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text('No trades available'),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _availableTrades.length,
                                itemBuilder: (ctx, i) => _buildTradeCard(_availableTrades[i]),
                              )
                        : _myTrades.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.list_alt, size: 64, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text('You have no trades'),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _myTrades.length,
                                itemBuilder: (ctx, i) => _buildTradeCard(_myTrades[i], isMyTrade: true),
                              ),
                  ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _createTrade,
          icon: const Icon(Icons.add),
          label: const Text('Create Trade'),
        ),
      ),
    );
  }
}
