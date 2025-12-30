import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/capture.dart';
import '../services/settings_service.dart';
import '../services/anti_cheat_service.dart';

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

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    captures = await JournalPage.loadCaptures();
    kidsMode = await SettingsService.getKidsMode();
    setState(() {});
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
        child: ListView.builder(
          itemCount: captures.length,
          itemBuilder: (ctx, i) {
            final c = captures[i];
            return Card(
              margin: const EdgeInsets.all(12),
              child: ListTile(
                leading: Image.file(Uri.parse(c.photoPath).isAbsolute ? File(c.photoPath) : File(c.photoPath)),
                title: Text(c.species ?? c.genus),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${c.group} • ${c.tier} • ${c.points} pts • ${c.geocell}"),
                    if (c.validationStatus == AntiCheatService.validationFlagged)
                      const Text(
                        "⚠️ Flagged",
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    if (c.livenessVerified)
                      const Text(
                        "✓ Liveness Verified",
                        style: TextStyle(color: Colors.green, fontSize: 12),
                      ),
                  ],
                ),
                trailing: Wrap(
                  spacing: 6,
                  children: [
                    if (c.flags["state_species"] == true)
                      const Chip(label: Text("State Species"), avatar: Icon(Icons.star, size: 16)),
                    if (c.flags["invasive"] == true)
                      const Chip(label: Text("Invasive"), avatar: Icon(Icons.warning_amber_rounded, size: 16)),
                    if (c.flags["venomous"] == true)
                      const Chip(label: Text("Venomous"), avatar: Icon(Icons.health_and_safety, size: 16)),
                    if (c.validationStatus == AntiCheatService.validationRejected)
                      const Chip(label: Text("Rejected"), avatar: Icon(Icons.block, size: 16), backgroundColor: Colors.red),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}