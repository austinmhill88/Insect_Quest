import 'package:flutter/material.dart';
import '../models/arthropod_card.dart';
import '../services/card_service.dart';
import '../widgets/card_renderer.dart';

/// Critter Codex page - displays the user's collection of minted cards.
///
/// Shows all cards in a scrollable grid with collection statistics.
/// Cards are displayed using the CardRenderer widget with placeholder frames.
class CritterCodexPage extends StatefulWidget {
  const CritterCodexPage({super.key});

  @override
  State<CritterCodexPage> createState() => _CritterCodexPageState();
}

class _CritterCodexPageState extends State<CritterCodexPage> {
  List<ArthropodCard> cards = [];
  Map<String, int> rarityCounts = {};
  int uniqueSpeciesCount = 0;
  int uniqueGenusCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  /// Load cards and collection statistics
  Future<void> _loadCards() async {
    setState(() => isLoading = true);
    
    cards = await CardService.loadCards();
    rarityCounts = await CardService.getCardCountsByRarity();
    uniqueSpeciesCount = await CardService.getUniqueSpeciesCount();
    uniqueGenusCount = await CardService.getUniqueGenusCount();
    
    setState(() => isLoading = false);
  }

  /// Build collection statistics widget
  Widget _buildStats() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Collection Statistics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total Cards', cards.length.toString(), Icons.style),
                _buildStatItem('Species', uniqueSpeciesCount.toString(), Icons.bug_report),
                _buildStatItem('Genera', uniqueGenusCount.toString(), Icons.category),
              ],
            ),
            const Divider(height: 24),
            const Text(
              'Rarity Distribution',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildRarityBar('Legendary', rarityCounts['Legendary'] ?? 0, Colors.amber.shade700),
            _buildRarityBar('Epic', rarityCounts['Epic'] ?? 0, Colors.purple.shade700),
            _buildRarityBar('Rare', rarityCounts['Rare'] ?? 0, Colors.blue.shade700),
            _buildRarityBar('Uncommon', rarityCounts['Uncommon'] ?? 0, Colors.green.shade700),
            _buildRarityBar('Common', rarityCounts['Common'] ?? 0, Colors.grey.shade700),
          ],
        ),
      ),
    );
  }

  /// Build individual stat item
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  /// Build rarity count bar
  Widget _buildRarityBar(String rarity, int count, Color color) {
    final total = cards.length;
    final percentage = total > 0 ? (count / total) : 0.0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              rarity,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: percentage,
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(
              count.toString(),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Critter Codex'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCards,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : cards.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.style_outlined,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Cards Yet',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Capture arthropods to mint cards!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCards,
                  child: ListView(
                    children: [
                      _buildStats(),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.67,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: cards.length,
                          itemBuilder: (context, index) {
                            final card = cards[index];
                            return GestureDetector(
                              onTap: () {
                                // Show card detail dialog
                                showDialog(
                                  context: context,
                                  builder: (ctx) => Dialog(
                                    child: SingleChildScrollView(
                                      child: CardRenderer(card: card),
                                    ),
                                  ),
                                );
                              },
                              child: CardRenderer(card: card),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
