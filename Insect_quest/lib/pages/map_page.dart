import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'journal_page.dart';
import '../models/capture.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? mapController;
  final LatLng start = const LatLng(34.0, -84.0);
  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  Future<void> _loadMarkers() async {
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
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: start, zoom: 8),
      onMapCreated: (c) => mapController = c,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      markers: markers,
    );
  }
}