import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/capture.dart';
import '../models/streak.dart';
import '../models/achievement.dart';
import '../services/settings_service.dart';
import '../services/streak_service.dart';
import '../services/coin_service.dart';
import '../services/achievement_service.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});
  static const _key = "captures";

  static Future<List<Capture>> loadCaptures() async {
    final sp = await SharedPreferences.getInstance();
    final txt = sp.getString(_key);
    if (txt == null) return [];
    final arr = jsonDecode(txt) as List<dynamic>;
    return arr.map((e) => Capture.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static Future<void> saveCapture(Capture cap) async {
    final list = await loadCaptures();
    list.add(cap);
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  List<Capture> captures = [];
  bool kidsMode = false;
  Streak streak = Streak();
  int coins = 0;
  List<Achievement> achievements = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    captures = await JournalPage.loadCaptures();
    kidsMode = await SettingsService.getKidsMode();
    streak = await StreakService.getCurrentStreak();
    coins = await CoinService.getCoins();
    achievements = await AchievementService.loadAchievements();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final unlockedAchievements = achievements.where((a) => a.unlocked).length;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: FilterChip(
              label: const Text("Kids Mode"),
              selected: kidsMode,
              onSelected: (v) async {
                await SettingsService.setKidsMode(v);
                await _refresh();
              },
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          children: [
            // Profile Stats Card
            Card(
              margin: const EdgeInsets.all(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          Icons.photo_camera,
                          'Captures',
                          '${captures.length}',
                        ),
                        _buildStatItem(
                          Icons.monetization_on,
                          'Coins',
                          '$coins',
                          color: Colors.amber,
                        ),
                        _buildStatItem(
                          Icons.local_fire_department,
                          'Streak',
                          '${streak.currentStreak}',
                          color: Colors.orange,
                        ),
                        _buildStatItem(
                          Icons.emoji_events,
                          'Achievements',
                          '$unlockedAchievements/${achievements.length}',
                          color: Colors.purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (streak.longestStreak > 0)
                      Text(
                        '🏆 Longest streak: ${streak.longestStreak} days',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Captures Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.book),
                  const SizedBox(width: 8),
                  const Text(
                    'Captures',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Captures List
            ...captures.map((c) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: Image.file(Uri.parse(c.photoPath).isAbsolute ? File(c.photoPath) : File(c.photoPath)),
                title: Text(c.species ?? c.genus),
                subtitle: Text("${c.group} • ${c.tier} • ${c.points} pts • ${c.geocell}"),
                trailing: Wrap(
                  spacing: 6,
                  children: [
                    if (c.flags["state_species"] == true)
                      const Chip(label: Text("State Species"), avatar: Icon(Icons.star, size: 16)),
                    if (c.flags["invasive"] == true)
                      const Chip(label: Text("Invasive"), avatar: Icon(Icons.warning_amber_rounded, size: 16)),
                    if (c.flags["venomous"] == true)
                      const Chip(label: Text("Venomous"), avatar: Icon(Icons.health_and_safety, size: 16)),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, {Color? color}) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}