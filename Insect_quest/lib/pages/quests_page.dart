import 'package:flutter/material.dart';
import '../models/quest.dart';
import '../services/quest_service.dart';
import '../services/coin_service.dart';

class QuestsPage extends StatefulWidget {
  const QuestsPage({super.key});

  @override
  State<QuestsPage> createState() => _QuestsPageState();
}

class _QuestsPageState extends State<QuestsPage> {
  List<Quest> quests = [];
  int coins = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => isLoading = true);
    
    await QuestService.initialize();
    quests = await QuestService.loadQuests();
    coins = await CoinService.getCoins();
    
    setState(() => isLoading = false);
  }

  Future<void> _claimReward(Quest quest) async {
    await QuestService.claimReward(quest.id);
    await CoinService.addCoins(quest.coinReward);
    
    // Show reward dialog
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('🎉 Reward Claimed!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('You earned ${quest.coinReward} coins!'),
              if (quest.foilReward) 
                const Text('\n✨ Bonus: Foil card chance increased!'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Awesome!'),
            ),
          ],
        ),
      );
    }
    
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final dailyQuests = quests.where((q) => q.period == QuestPeriod.daily).toList();
    final weeklyQuests = quests.where((q) => q.period == QuestPeriod.weekly).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quests'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '$coins',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Daily Quests Section
            _buildSectionHeader('Daily Quests', Icons.wb_sunny),
            const SizedBox(height: 8),
            if (dailyQuests.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No daily quests available'),
                ),
              )
            else
              ...dailyQuests.map((q) => _buildQuestCard(q)),
            
            const SizedBox(height: 24),
            
            // Weekly Quests Section
            _buildSectionHeader('Weekly Quests', Icons.calendar_today),
            const SizedBox(height: 8),
            if (weeklyQuests.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No weekly quests available'),
                ),
              )
            else
              ...weeklyQuests.map((q) => _buildQuestCard(q)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestCard(Quest quest) {
    final progress = quest.progress.clamp(0, quest.target);
    final progressPercent = quest.target > 0 ? progress / quest.target : 0.0;
    final isExpired = quest.expiresAt.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: quest.completed && !quest.claimed ? 4 : 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Reward
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    quest.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration: quest.claimed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.monetization_on, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '${quest.coinReward}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (quest.foilReward) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.auto_awesome, size: 16, color: Colors.purple),
                    ],
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Description
            Text(
              quest.description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress: $progress / ${quest.target}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (!isExpired)
                      Text(
                        _formatTimeRemaining(quest.expiresAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progressPercent,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    quest.completed ? Colors.green : Colors.blue,
                  ),
                ),
              ],
            ),
            
            // Claim Button
            if (quest.completed && !quest.claimed)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _claimReward(quest),
                    icon: const Icon(Icons.card_giftcard),
                    label: const Text('Claim Reward'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
            
            // Completed Badge
            if (quest.claimed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                    const SizedBox(width: 4),
                    Text(
                      'Completed',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Expired Badge
            if (isExpired && !quest.completed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.red[700], size: 20),
                    const SizedBox(width: 4),
                    Text(
                      'Expired',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimeRemaining(DateTime expiresAt) {
    final now = DateTime.now();
    final difference = expiresAt.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d remaining';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h remaining';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m remaining';
    } else {
      return 'Expires soon';
    }
  }
}
