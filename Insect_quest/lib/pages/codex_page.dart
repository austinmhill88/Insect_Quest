import 'dart:io';
import 'package:flutter/material.dart';
import '../models/capture.dart';
import '../pages/journal_page.dart';
import 'card_detail_page.dart';

class CodexPage extends StatefulWidget {
  const CodexPage({super.key});

  @override
  State<CodexPage> createState() => _CodexPageState();
}

class _CodexPageState extends State<CodexPage> {
  List<Capture> captures = [];
  List<Capture> filteredCaptures = [];
  
  // Filter state
  String? selectedRarity;
  String? selectedGenus;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    captures = await JournalPage.loadCaptures();
    _applyFilters();
  }

  void _applyFilters() {
    filteredCaptures = captures.where((capture) {
      // Filter by rarity
      if (selectedRarity != null && capture.tier != selectedRarity) {
        return false;
      }
      
      // Filter by genus
      if (selectedGenus != null && capture.genus != selectedGenus) {
        return false;
      }
      
      // Filter by search query (genus or species)
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final genus = capture.genus.toLowerCase();
        final species = capture.species?.toLowerCase() ?? '';
        if (!genus.contains(query) && !species.contains(query)) {
          return false;
        }
      }
      
      return true;
    }).toList();
    
    setState(() {});
  }

  Color _getRarityColor(String tier) {
    switch (tier) {
      case 'Common':
        return Colors.grey;
      case 'Uncommon':
        return Colors.green;
      case 'Rare':
        return Colors.blue;
      case 'Epic':
        return Colors.purple;
      case 'Legendary':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  IconData _getRarityIcon(String tier) {
    switch (tier) {
      case 'Common':
        return Icons.circle;
      case 'Uncommon':
        return Icons.album;
      case 'Rare':
        return Icons.hexagon;
      case 'Epic':
        return Icons.stars;
      case 'Legendary':
        return Icons.auto_awesome;
      default:
        return Icons.circle;
    }
  }

  List<String> _getUniqueRarities() {
    return captures.map((c) => c.tier).toSet().toList()..sort();
  }

  List<String> _getUniqueGenera() {
    return captures.map((c) => c.genus).toSet().toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Critter Codex'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter section
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Column(
              children: [
                // Search bar
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search genus or species',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    searchQuery = value;
                    _applyFilters();
                  },
                ),
                const SizedBox(height: 8),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Rarity filter
                      FilterChip(
                        label: Text(selectedRarity ?? 'All Rarities'),
                        selected: selectedRarity != null,
                        onSelected: (selected) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Filter by Rarity'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    title: const Text('All'),
                                    onTap: () {
                                      setState(() => selectedRarity = null);
                                      _applyFilters();
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ..._getUniqueRarities().map((rarity) => ListTile(
                                    leading: Icon(
                                      _getRarityIcon(rarity),
                                      color: _getRarityColor(rarity),
                                    ),
                                    title: Text(rarity),
                                    onTap: () {
                                      setState(() => selectedRarity = rarity);
                                      _applyFilters();
                                      Navigator.pop(context);
                                    },
                                  )),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      // Genus filter
                      FilterChip(
                        label: Text(selectedGenus ?? 'All Genera'),
                        selected: selectedGenus != null,
                        onSelected: (selected) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Filter by Genus'),
                              content: SizedBox(
                                width: double.maxFinite,
                                child: ListView(
                                  shrinkWrap: true,
                                  children: [
                                    ListTile(
                                      title: const Text('All'),
                                      onTap: () {
                                        setState(() => selectedGenus = null);
                                        _applyFilters();
                                        Navigator.pop(context);
                                      },
                                    ),
                                    ..._getUniqueGenera().map((genus) => ListTile(
                                      title: Text(genus),
                                      onTap: () {
                                        setState(() => selectedGenus = genus);
                                        _applyFilters();
                                        Navigator.pop(context);
                                      },
                                    )),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      // Clear filters
                      if (selectedRarity != null || selectedGenus != null || searchQuery.isNotEmpty)
                        ActionChip(
                          label: const Text('Clear Filters'),
                          onPressed: () {
                            setState(() {
                              selectedRarity = null;
                              selectedGenus = null;
                              searchQuery = '';
                            });
                            _applyFilters();
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Results count
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Showing ${filteredCaptures.length} of ${captures.length} cards',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          // Grid view
          Expanded(
            child: filteredCaptures.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.catching_pokemon,
                          size: 64,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          captures.isEmpty
                              ? 'No cards collected yet!\nGo capture some critters!'
                              : 'No cards match your filters',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: filteredCaptures.length,
                      itemBuilder: (context, index) {
                        final capture = filteredCaptures[index];
                        return _buildCardTile(context, capture);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardTile(BuildContext context, Capture capture) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CardDetailPage(capture: capture),
          ),
        ).then((_) => _refresh());
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card image with frame
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  Image.file(
                    File(capture.photoPath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.bug_report, size: 48),
                      );
                    },
                  ),
                  // Gradient overlay for better text visibility
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            capture.species ?? capture.genus,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            capture.group,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Rarity badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _getRarityColor(capture.tier),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getRarityIcon(capture.tier),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  // Special flags
                  if (capture.flags["state_species"] == true)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Card footer with points
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: _getRarityColor(capture.tier).withOpacity(0.2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${capture.points} pts',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getRarityColor(capture.tier).withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Q: ${(capture.quality * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
