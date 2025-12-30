import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'journal_page.dart';
import '../models/capture.dart';
import '../services/settings_service.dart';
import '../widgets/pin_dialogs.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? mapController;
  final LatLng start = const LatLng(34.0, -84.0);
  Set<Marker> markers = {};
  bool kidsMode = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final km = await SettingsService.getKidsMode();
    setState(() => kidsMode = km);
    await _loadMarkers();
  }

  Future<void> _loadMarkers() async {
    // Task 8: Kids Mode - do not show markers on map
    if (kidsMode) {
      setState(() => markers = {});
      return;
    }

    final caps = await JournalPage.loadCaptures();
    final m = <Marker>{};
    for (final c in caps) {
      final parts = c.geocell.split(',');
      final lat = double.tryParse(parts[0]) ?? c.lat;
      final lon = double.tryParse(parts[1]) ?? c.lon;
      m.add(Marker(
        markerId: MarkerId(c.id),
        position: LatLng(lat, lon),
        infoWindow: InfoWindow(title: c.species ?? c.genus, snippet: "${c.tier} • ${c.points} pts"),
      ));
    }
    setState(() => markers = m);
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
    setState(() => kidsMode = newValue);
    await _loadMarkers();
    
    if (mounted) {
      final message = newValue
          ? "🛡️ Kids Mode enabled - Map markers hidden for privacy"
          : "Kids Mode disabled - Map markers visible";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: start, zoom: 8),
          onMapCreated: (c) => mapController = c,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          markers: markers,
        ),
        if (kidsMode)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  "🔒 Kids Mode: Map markers are hidden for privacy",
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}