import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/capture.dart';
import '../services/settings_service.dart';
import '../services/quest_service.dart';
import '../models/quest.dart';
import '../widgets/pin_dialogs.dart';

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

class _JournalPageState extends State<JournalPage> with SingleTickerProviderStateMixin {
  List<Capture> captures = [];
  bool kidsMode = false;
  int _selectedTab = 0; // 0 = Captures, 1 = Quests
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    captures = await JournalPage.loadCaptures();
    kidsMode = await SettingsService.getKidsMode();
    setState(() {});
  }

  Future<void> _toggleKidsMode(bool newValue) async {
    // If turning OFF Kids Mode, require PIN verification
    if (!newValue && kidsMode) {
      final isPinSetup = await SettingsService.isPinSetup();
      
      if (!isPinSetup) {
        // First time - set up PIN
        final pin = await showDialog<String>(
          context: context,
          builder: (ctx) => const PinSetupDialog(),
        );
        
        if (pin == null) return; // User cancelled
        await SettingsService.setPin(pin);
      }
      
      // Verify PIN
      final enteredPin = await showDialog<String>(
        context: context,
        builder: (ctx) => const PinVerifyDialog(
          title: "🔒 Disable Kids Mode",
          message: "Enter your parental PIN to disable Kids Mode",
        ),
      );
      
      if (enteredPin == null) return; // User cancelled
      
      final isValid = await SettingsService.verifyPin(enteredPin);
      if (!isValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ Incorrect PIN")),
          );
        }
        return;
      }
    }
    
    // Update Kids Mode
    await SettingsService.setKidsMode(newValue);
    await _refresh();
    
    if (mounted) {
      final message = newValue
          ? "🛡️ Kids Mode enabled - Safe and fun!"
          : "Kids Mode disabled";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: FilterChip(
              label: const Text("Kids Mode"),
              selected: kidsMode,
              onSelected: _toggleKidsMode,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Captures", icon: Icon(Icons.photo_library)),
            Tab(text: "Quests", icon: Icon(Icons.flag)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCapturesTab(),
          _buildQuestsTab(),
        ],
      ),
    );
  }

  Widget _buildCapturesTab() {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        itemCount: captures.length,
        itemBuilder: (ctx, i) {
          final c = captures[i];
          return Card(
            margin: const EdgeInsets.all(12),
            child: ListTile(
              leading: Image.file(File(c.photoPath)),
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
          );
        },
      ),
    );
  }

  Widget _buildQuestsTab() {
    final availableQuests = QuestService.getAvailableQuests(kidsMode);
    
    return FutureBuilder<Map<String, QuestProgress>>(
      future: QuestService.loadProgress(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final progress = snapshot.data!;
        
        return ListView.builder(
          itemCount: availableQuests.length,
          itemBuilder: (ctx, i) {
            final quest = availableQuests[i];
            final questProgress = progress[quest.id] ?? QuestProgress(questId: quest.id);
            final percent = (questProgress.currentCount / quest.targetCount).clamp(0.0, 1.0);
            
            return Card(
              margin: const EdgeInsets.all(12),
              color: questProgress.completed ? Colors.green.shade50 : null,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: questProgress.completed ? Colors.green : Colors.blue,
                  child: Text(
                    quest.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                title: Text(
                  quest.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: questProgress.completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(quest.description),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: percent,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        questProgress.completed ? Colors.green : Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${questProgress.currentCount}/${quest.targetCount} • ${quest.rewardPoints} pts",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                trailing: questProgress.completed
                    ? const Icon(Icons.check_circle, color: Colors.green, size: 32)
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}