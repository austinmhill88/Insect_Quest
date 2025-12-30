import '../models/capture.dart';

/// Service for calculating regional leaderboard statistics by geocell.
/// 
/// Each geocell represents a coarse location (~1km radius) and contains:
/// - Total captures (card count)
/// - Total points earned (coins)
/// - List of all captures in that cell
/// 
/// This service ensures no precise locations are exposed, maintaining privacy.
class LeaderboardService {
  /// Aggregates captures by geocell.
  /// 
  /// Returns a Map where:
  /// - Key: geocell string (e.g., "34.00,-84.00")
  /// - Value: Map containing 'captures', 'cardCount', and 'totalPoints'
  static Map<String, Map<String, dynamic>> aggregateByGeocell(List<Capture> captures) {
    final Map<String, Map<String, dynamic>> geocellMap = {};
    
    for (final capture in captures) {
      final geocell = capture.geocell;
      
      if (!geocellMap.containsKey(geocell)) {
        geocellMap[geocell] = {
          'captures': <Capture>[],
          'cardCount': 0,
          'totalPoints': 0,
        };
      }
      
      geocellMap[geocell]!['captures'].add(capture);
      geocellMap[geocell]!['cardCount']++;
      geocellMap[geocell]!['totalPoints'] += capture.points;
    }
    
    return geocellMap;
  }
  
  /// Gets sorted leaderboard entries by total points (descending).
  /// 
  /// Returns a list of geocell data sorted by points, useful for displaying
  /// regional rankings.
  static List<Map<String, dynamic>> getSortedLeaderboard(List<Capture> captures) {
    final aggregated = aggregateByGeocell(captures);
    
    final entries = aggregated.entries.map((entry) {
      return {
        'geocell': entry.key,
        'cardCount': entry.value['cardCount'],
        'totalPoints': entry.value['totalPoints'],
        'captures': entry.value['captures'],
      };
    }).toList();
    
    // Sort by total points descending
    entries.sort((a, b) => (b['totalPoints'] as int).compareTo(a['totalPoints'] as int));
    
    return entries;
  }
  
  /// Extracts lat/lon from geocell string.
  /// 
  /// Returns a Map with 'lat' and 'lon' keys, or null if parsing fails.
  static Map<String, double>? parseGeocell(String geocell) {
    try {
      final parts = geocell.split(',');
      if (parts.length == 2) {
        return {
          'lat': double.parse(parts[0]),
          'lon': double.parse(parts[1]),
        };
      }
    } catch (e) {
      // Invalid geocell format
    }
    return null;
  }
}
