import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'journal_page.dart';
import '../models/capture.dart';
import '../services/settings_service.dart';
import '../services/leaderboard_service.dart';

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
  Map<String, Map<String, dynamic>> geocellData = {};

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
    // Kids Mode - do not show markers on map for privacy
    if (kidsMode) {
      setState(() {
        markers = {};
        geocellData = {};
      });
      return;
    }

    final caps = await JournalPage.loadCaptures();
    
    // Aggregate captures by geocell (no precise locations)
    final aggregated = LeaderboardService.aggregateByGeocell(caps);
    geocellData = aggregated;
    
    final m = <Marker>{};
    
    // Create one marker per geocell with aggregated data
    for (final entry in aggregated.entries) {
      final geocell = entry.key;
      final data = entry.value;
      final cardCount = data['cardCount'] as int;
      final totalPoints = data['totalPoints'] as int;
      
      // Parse geocell to get coarse lat/lon
      final coords = LeaderboardService.parseGeocell(geocell);
      if (coords == null) continue;
      
      final lat = coords['lat']!;
      final lon = coords['lon']!;
      
      m.add(Marker(
        markerId: MarkerId(geocell),
        position: LatLng(lat, lon),
        infoWindow: InfoWindow(
          title: '$cardCount card${cardCount == 1 ? '' : 's'}',
          snippet: '$totalPoints points',
        ),
        onTap: () => _showGeocellLeaders(geocell, data),
      ));
    }
    
    setState(() => markers = m);
  }
  
  /// Shows a bottom sheet with the leader list for a specific geocell.
  /// Displays all captures in that cell sorted by points.
  void _showGeocellLeaders(String geocell, Map<String, dynamic> data) {
    final captures = List<Capture>.from(data['captures']);
    final cardCount = data['cardCount'] as int;
    final totalPoints = data['totalPoints'] as int;
    
    // Sort captures by points descending
    captures.sort((a, b) => b.points.compareTo(a.points));
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
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
                      'Region: $geocell',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
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
                  itemBuilder: (ctx, index) {
                    final capture = captures[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getTierColor(capture.tier),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(capture.species ?? capture.genus),
                      subtitle: Text('${capture.tier} • ${capture.group}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${capture.points} pts',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Q: ${capture.quality.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12,
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
  
  Color _getTierColor(String tier) {
    switch (tier) {
      case 'Legendary':
        return Colors.purple;
      case 'Epic':
        return Colors.deepPurple;
      case 'Rare':
        return Colors.blue;
      case 'Uncommon':
        return Colors.green;
      case 'Common':
      default:
        return Colors.grey;
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