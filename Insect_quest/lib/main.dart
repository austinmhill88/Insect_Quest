import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/camera_page.dart';
import 'pages/map_page.dart';
import 'pages/journal_page.dart';
import 'pages/economy_page.dart';
import 'pages/trading_page.dart';
import 'services/catalog_service.dart';
import 'config/feature_flags.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (stub for MVP - uses default config)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Firebase not configured - will use local storage only
    debugPrint("Firebase not configured: $e");
  }
  
  final catalogService = CatalogService();
  await catalogService.loadCatalog();
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
      routes: {
        '/economy': (context) => const EconomyPage(),
        '/trading': (context) => const TradingPage(),
      },
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
      const EconomyPage(),
    ];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.camera_alt), label: 'Capture'),
          NavigationDestination(icon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.book), label: 'Journal'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: 'Economy'),
        ],
        onDestinationSelected: (i) => setState(() => index = i),
      ),
    );
  }
}