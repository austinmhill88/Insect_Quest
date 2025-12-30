import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:exif/exif.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Anti-cheat service for validating photo captures
/// Provides EXIF validation, duplicate detection, and logging
class AntiCheatService {
  static const String _hashesKey = 'photo_hashes';
  static const String _logFileName = 'anti_cheat_log.json';
  
  /// Validation result from anti-cheat checks
  static const String validationValid = 'valid';
  static const String validationFlagged = 'flagged';
  static const String validationRejected = 'rejected';
  
  /// Check if photo has valid EXIF data from a real camera
  /// Returns true if EXIF data contains camera-specific fields
  /// Returns false for screenshots, scans, or edited photos
  static Future<bool> hasValidExif(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final data = await readExifFromBytes(bytes);
      
      if (data.isEmpty) {
        await _logSuspiciousCapture(
          imagePath, 
          'No EXIF data found',
          'rejected'
        );
        return false;
      }
      
      // Check for camera-specific EXIF tags
      // Real cameras include Make, Model, and other metadata
      final hasMake = data.containsKey('Image Make');
      final hasModel = data.containsKey('Image Model');
      final hasDateTime = data.containsKey('Image DateTime') || 
                         data.containsKey('EXIF DateTimeOriginal');
      
      // Look for camera-specific tags that screenshots won't have
      final hasSoftware = data.containsKey('Image Software');
      final hasOrientation = data.containsKey('Image Orientation');
      
      // Real photos should have make/model OR datetime + orientation
      // Screenshots often have software tag but missing camera info
      if (hasSoftware && !hasMake && !hasModel) {
        await _logSuspiciousCapture(
          imagePath,
          'Photo appears to be a screenshot (has Software tag but no camera Make/Model)',
          'flagged'
        );
        return false;
      }
      
      if (!hasMake && !hasModel && !hasDateTime) {
        await _logSuspiciousCapture(
          imagePath,
          'Missing critical EXIF fields (no Make, Model, or DateTime)',
          'flagged'
        );
        return false;
      }
      
      return true;
    } catch (e) {
      // If EXIF reading fails, log but don't block (could be valid photo)
      await _logSuspiciousCapture(
        imagePath,
        'EXIF read error: $e',
        'flagged'
      );
      return true; // Allow with warning
    }
  }
  
  /// Generate perceptual hash for an image
  /// Uses difference hash (dHash) algorithm for duplicate detection
  static Future<String> generatePerceptualHash(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }
      
      // Resize to 9x8 for dHash (difference hash)
      final resized = img.copyResize(image, width: 9, height: 8);
      
      // Convert to grayscale and compute hash
      final hash = StringBuffer();
      for (int y = 0; y < 8; y++) {
        for (int x = 0; x < 8; x++) {
          final pixel1 = resized.getPixel(x, y);
          final pixel2 = resized.getPixel(x + 1, y);
          
          final gray1 = img.getLuminance(pixel1);
          final gray2 = img.getLuminance(pixel2);
          
          hash.write(gray1 > gray2 ? '1' : '0');
        }
      }
      
      // Convert binary string to hex for compact storage
      final binaryStr = hash.toString();
      final hexHash = StringBuffer();
      for (int i = 0; i < binaryStr.length; i += 4) {
        final chunk = binaryStr.substring(i, i + 4);
        hexHash.write(int.parse(chunk, radix: 2).toRadixString(16));
      }
      
      return hexHash.toString();
    } catch (e) {
      await _logSuspiciousCapture(
        imagePath,
        'Hash generation error: $e',
        'flagged'
      );
      // Return a random hash so it won't match duplicates
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }
  
  /// Check if photo is a duplicate of a previously captured photo
  /// Returns true if a similar photo has been minted before
  static Future<bool> isDuplicate(String photoHash) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hashesJson = prefs.getString(_hashesKey);
      
      if (hashesJson == null) {
        return false;
      }
      
      final List<dynamic> hashes = jsonDecode(hashesJson);
      
      // Check for exact match first
      if (hashes.contains(photoHash)) {
        return true;
      }
      
      // Check for near-duplicates (Hamming distance <= 5)
      // This catches slightly cropped or compressed versions
      for (final storedHash in hashes) {
        if (storedHash is String && _hammingDistance(photoHash, storedHash) <= 5) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      // If check fails, allow the capture (don't block on errors)
      return false;
    }
  }
  
  /// Store photo hash to prevent future duplicates
  static Future<void> storePhotoHash(String photoHash) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hashesJson = prefs.getString(_hashesKey);
      
      List<dynamic> hashes = [];
      if (hashesJson != null) {
        hashes = jsonDecode(hashesJson);
      }
      
      hashes.add(photoHash);
      await prefs.setString(_hashesKey, jsonEncode(hashes));
    } catch (e) {
      // Silently fail - don't block capture if storage fails
    }
  }
  
  /// Calculate Hamming distance between two hex hash strings
  static int _hammingDistance(String hash1, String hash2) {
    if (hash1.length != hash2.length) {
      return 999; // Not similar if different lengths
    }
    
    int distance = 0;
    for (int i = 0; i < hash1.length; i++) {
      if (hash1[i] != hash2[i]) {
        // Count bit differences in hex digits
        final val1 = int.parse(hash1[i], radix: 16);
        final val2 = int.parse(hash2[i], radix: 16);
        final xor = val1 ^ val2;
        // Count set bits using Brian Kernighan's algorithm
        int bits = xor;
        while (bits > 0) {
          distance++;
          bits &= bits - 1; // Clear the lowest set bit
        }
      }
    }
    return distance;
  }
  
  /// Log suspicious or rejected capture for admin review
  static Future<void> _logSuspiciousCapture(
    String imagePath,
    String reason,
    String status,
  ) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logFile = File('${dir.path}/$_logFileName');
      
      List<dynamic> logs = [];
      if (await logFile.exists()) {
        final content = await logFile.readAsString();
        logs = jsonDecode(content);
      }
      
      logs.add({
        'timestamp': DateTime.now().toIso8601String(),
        'imagePath': imagePath,
        'reason': reason,
        'status': status,
      });
      
      await logFile.writeAsString(jsonEncode(logs));
    } catch (e) {
      // Silently fail - logging shouldn't block captures
    }
  }
  
  /// Get all logged suspicious captures for admin review
  static Future<List<Map<String, dynamic>>> getSuspiciousCaptures() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logFile = File('${dir.path}/$_logFileName');
      
      if (!await logFile.exists()) {
        return [];
      }
      
      final content = await logFile.readAsString();
      final List<dynamic> logs = jsonDecode(content);
      return logs.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }
  
  /// Clear all suspicious capture logs (admin function)
  static Future<void> clearLogs() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logFile = File('${dir.path}/$_logFileName');
      
      if (await logFile.exists()) {
        await logFile.delete();
      }
    } catch (e) {
      // Silently fail
    }
  }
  
  /// Validate a photo capture through all anti-cheat checks
  /// Returns validation result and metadata
  static Future<Map<String, dynamic>> validateCapture(String imagePath) async {
    // Check EXIF data
    final hasExif = await hasValidExif(imagePath);
    
    // Generate perceptual hash
    final photoHash = await generatePerceptualHash(imagePath);
    
    // Check for duplicates
    final isDupe = await isDuplicate(photoHash);
    
    String validationStatus = validationValid;
    String? rejectionReason;
    
    // Determine validation status
    if (isDupe) {
      validationStatus = validationRejected;
      rejectionReason = 'Duplicate photo detected';
      await _logSuspiciousCapture(
        imagePath,
        rejectionReason!,
        validationStatus,
      );
    } else if (!hasExif) {
      validationStatus = validationRejected;
      rejectionReason = 'Invalid or missing EXIF data';
    }
    
    // Store hash if valid or flagged (not if rejected)
    if (validationStatus != validationRejected) {
      await storePhotoHash(photoHash);
    }
    
    return {
      'validationStatus': validationStatus,
      'photoHash': photoHash,
      'hasExif': hasExif,
      'isDuplicate': isDupe,
      'rejectionReason': rejectionReason,
    };
  }
}
