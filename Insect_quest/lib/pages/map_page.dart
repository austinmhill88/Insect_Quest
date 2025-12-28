import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'journal_page.dart';
import '../models/capture.dart';
import '../services/settings_service.dart';

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