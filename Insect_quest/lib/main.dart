import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/camera_page.dart';
import 'pages/map_page.dart';
import 'pages/journal_page.dart';
import 'pages/quests_page.dart';
 
import 'pages/leaderboard_page.dart';

import 'pages/admin_page.dart';

import 'services/catalog_service.dart';
import 'services/quest_service.dart';
import 'config/feature_flags.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final catalogService = CatalogService();
  await catalogService.loadCatalog();
  
  // Initialize quest system
  await QuestService.initialize();
  
  runApp(InsectQuestApp(catalogService: catalogService));
}

class InsectQuestApp extends StatelessWidget {
  final CatalogService catalogService;
  const InsectQuestApp({super.key, required this.catalogService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InsectQuest',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: HomeNav(catalogService: catalogService),
    );
  }
}

class HomeNav extends StatefulWidget {
  final CatalogService catalogService;
  const HomeNav({super.key, required this.catalogService});
  @override
  State<HomeNav> createState() => _HomeNavState();
}

class _HomeNavState extends State<HomeNav> {
  int index = 0;
  late final List<Widget> pages;

  @override
  void initState() {
    pages = [
      CameraPage(catalogService: widget.catalogService),
      const MapPage(),
      const JournalPage(),
      const QuestsPage(),
      const LeaderboardPage(),
    ];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: index == 2 ? AppBar(
        title: const Text('InsectQuest'),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const AdminPage()),
              );
            },
            tooltip: 'Admin Panel',
          ),
        ],
      ) : null,
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.camera_alt), label: 'Capture'),
          NavigationDestination(icon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.book), label: 'Journal'),
          NavigationDestination(icon: Icon(Icons.emoji_events), label: 'Quests'),
          NavigationDestination(icon: Icon(Icons.emoji_events), label: 'Leaders'),
        ],
        onDestinationSelected: (i) => setState(() => index = i),
      ),
    );
  }
}