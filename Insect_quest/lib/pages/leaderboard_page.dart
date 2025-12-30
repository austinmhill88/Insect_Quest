import 'package:flutter/material.dart';
import '../models/capture.dart';
import '../services/leaderboard_service.dart';
import '../services/settings_service.dart';
import '../utils/ui_utils.dart';
import 'journal_page.dart';

/// Regional Leaderboard Page
/// 
/// Displays aggregated statistics by geocell:
/// - Card count (number of captures in each region)
/// - Total points (coins) earned in each region
/// - Sorted by total points descending
/// 
/// Respects Kids Mode privacy settings - hidden when Kids Mode is active.
class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});
  
  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  List<Map<String, dynamic>> leaderboard = [];
  bool kidsMode = false;
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }
  
  Future<void> _loadLeaderboard() async {
    setState(() => isLoading = true);
    
    final km = await SettingsService.getKidsMode();
    final caps = await JournalPage.loadCaptures();
    
    // Calculate regional leaderboard
    final sorted = LeaderboardService.getSortedLeaderboard(caps);
    
    setState(() {
      kidsMode = km;
      leaderboard = sorted;
      isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Regional Leaderboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLeaderboard,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : kidsMode
              ? _buildKidsModePrivacyMessage()
              : leaderboard.isEmpty
                  ? _buildEmptyState()
                  : _buildLeaderboard(),
    );
  }
  
  Widget _buildKidsModePrivacyMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Leaderboard Hidden',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Kids Mode is active. Regional leaderboard is hidden for privacy.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                await SettingsService.setKidsMode(false);
                await _loadLeaderboard();
              },
              icon: const Icon(Icons.lock_open),
              label: const Text('Disable Kids Mode'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Captures Yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Start capturing insects to see regional leaderboard rankings!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLeaderboard() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: leaderboard.length,
      itemBuilder: (ctx, index) {
        final entry = leaderboard[index];
        final geocell = entry['geocell'] as String;
        final cardCount = entry['cardCount'] as int;
        final totalPoints = entry['totalPoints'] as int;
        final captures = List<Capture>.from(entry['captures']);
        
        // Medal icons for top 3
        IconData? medal;
        Color? medalColor;
        if (index == 0) {
          medal = Icons.emoji_events;
          medalColor = Colors.amber;
        } else if (index == 1) {
          medal = Icons.emoji_events;
          medalColor = Colors.grey[400];
        } else if (index == 2) {
          medal = Icons.emoji_events;
          medalColor = Colors.brown[400];
        }
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: medal != null ? medalColor : Colors.blue[100],
              child: medal != null
                  ? Icon(medal, color: Colors.white)
                  : Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            title: Text(
              'Region: $geocell',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('$cardCount card${cardCount == 1 ? '' : 's'}'),
                Text('${_getTopSpecies(captures)} unique species'),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$totalPoints',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const Text(
                  'points',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            onTap: () => _showRegionDetails(geocell, captures, cardCount, totalPoints),
          ),
        );
      },
    );
  }
  
  int _getTopSpecies(List<Capture> captures) {
    final species = <String>{};
    for (final c in captures) {
      if (c.species != null) {
        species.add(c.species!);
      }
    }
    return species.length;
  }
  
  void _showRegionDetails(String geocell, List<Capture> captures, int cardCount, int totalPoints) {
    // Sort by points
    captures.sort((a, b) => b.points.compareTo(a.points));
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Region Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Location: $geocell',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '$cardCount cards • $totalPoints points',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const Divider(height: 24),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: captures.length,
                  itemBuilder: (ctx, i) {
                    final c = captures[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: UIUtils.getTierColor(c.tier),
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(c.species ?? c.genus),
                      subtitle: Text('${c.tier} • ${c.group}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${c.points}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'pts',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
