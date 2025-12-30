import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';
import '../config/scoring.dart';
import '../config/feature_flags.dart';
import '../models/capture.dart';
import '../models/arthropod_card.dart';
import '../services/ml_stub.dart';
import '../services/catalog_service.dart';
import '../services/settings_service.dart';
import '../services/card_service.dart';
import '../models/quest.dart';
import '../models/achievement.dart';
import '../services/ml_stub.dart';
import '../services/catalog_service.dart';
import '../services/settings_service.dart';
import '../services/quest_service.dart';
import '../widgets/pin_dialogs.dart';
import '../services/streak_service.dart';
import '../services/achievement_service.dart';
import '../services/anti_cheat_service.dart';
import '../services/liveness_service.dart';
import 'journal_page.dart';

class CameraPage extends StatefulWidget {
  final CatalogService catalogService;
  const CameraPage({super.key, required this.catalogService});
  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? controller;
  List<CameraDescription>? cameras;
  bool ready = false;
  late final MLService ml;
  bool kidsMode = Flags.kidsModeDefault;

  @override
  void initState() {
    super.initState();
    ml = MLService(catalogService: widget.catalogService);
    _init();
    _loadKidsMode();
  }

  Future<void> _loadKidsMode() async {
    final km = await SettingsService.getKidsMode();
    setState(() => kidsMode = km);
  }

  Future<void> _init() async {
    cameras = await availableCameras();
    controller = CameraController(cameras!.first, ResolutionPreset.high, enableAudio: false);
    await controller!.initialize();
    setState(() => ready = true);
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  double _computeSharpness(img.Image im) {
    // Laplacian-like measure (simple proxy)
    double sum = 0;
    for (int y = 1; y < im.height - 1; y += 10) {
      for (int x = 1; x < im.width - 1; x += 10) {
        final c = img.getLuminance(im.getPixel(x, y)).toDouble();
        final up = img.getLuminance(im.getPixel(x, y - 1)).toDouble();
        final dn = img.getLuminance(im.getPixel(x, y + 1)).toDouble();
        final lf = img.getLuminance(im.getPixel(x - 1, y)).toDouble();
        final rt = img.getLuminance(im.getPixel(x + 1, y)).toDouble();
        final lap = (4 * c) - (up + dn + lf + rt);
        sum += lap.abs();
      }
    }
    // Normalize to 0.85–1.10 range
    double s = 0.85 + min(sum / 500000.0, 0.25);
    return s.clamp(0.85, 1.10);
  }

  double _computeExposure(img.Image im) {
    int midtones = 0, total = 0;
    for (int y = 0; y < im.height; y += 20) {
      for (int x = 0; x < im.width; x += 20) {
        final lum = img.getLuminance(im.getPixel(x, y));
        total++;
        if (lum > 60 && lum < 190) midtones++;
      }
    }
    final ratio = midtones / max(total, 1);
    double e = 0.90 + (ratio * 0.15); // 0.90–1.05
    return e.clamp(0.90, 1.05);
  }

  double _computeFraming(img.Image im) {
    // Heuristic: central crop brightness vs edges
    final cx = im.width ~/ 2;
    final cy = im.height ~/ 2;
    int centerSum = 0, edgeSum = 0;
    int centerCount = 0, edgeCount = 0;

    for (int y = 0; y < im.height; y += 15) {
      for (int x = 0; x < im.width; x += 15) {
        final lum = img.getLuminance(im.getPixel(x, y));
        final dist = sqrt(pow((x - cx).abs().toDouble(), 2) + pow((y - cy).abs().toDouble(), 2));
        if (dist < min(im.width, im.height) * 0.25) {
          centerSum += lum;
          centerCount++;
        } else {
          edgeSum += lum;
          edgeCount++;
        }
      }
    }
    final centerAvg = centerSum / max(centerCount, 1);
    final edgeAvg = edgeSum / max(edgeCount, 1);
    final ratio = centerAvg / max(edgeAvg, 1);
    double f = 0.90 + min((ratio - 1.0) * 0.2, 0.25); // reward centered subject
    return f.clamp(0.90, 1.15);
  }

  String _geocell(double lat, double lon) {
    // Coarse ~1km cell using rounding
    double latR = (lat * 100).roundToDouble() / 100.0;
    double lonR = (lon * 100).roundToDouble() / 100.0;
    return "${latR.toStringAsFixed(2)},${lonR.toStringAsFixed(2)}";
  }

  Future<void> _capture() async {
    final file = await controller!.takePicture();
    final bytes = await File(file.path).readAsBytes();
    final im = img.decodeImage(bytes)!;

    // Quality
    final sharpness = _computeSharpness(im);
    final exposure = _computeExposure(im);
    final framing = _computeFraming(im);
    final qMult = Scoring.qualityMultiplier(
      sharpness: sharpness,
      exposure: exposure,
      framing: framing,
      kidsMode: kidsMode,
    );

    // Task 10: Retake prompt for low-quality shots
    if (sharpness < 0.9 || framing < 0.9) {
      if (mounted) {
        final retake = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Low Quality Photo"),
            content: const Text("The photo quality is low. Would you like to retake it?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Keep anyway"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Retake"),
              ),
            ],
          ),
        );
        if (retake == true) {
          return; // Exit without saving
        }
      }
    }

    // Location - use only coarse geocell coordinates (no precise locations saved)
    // Anti-cheat validation
    Map<String, dynamic> validationResult = {
      'validationStatus': AntiCheatService.validationValid,
      'photoHash': '',
      'hasExif': true,
      'isDuplicate': false,
    };
    
    if (Flags.exifValidationEnabled || Flags.duplicateDetectionEnabled) {
      validationResult = await AntiCheatService.validateCapture(file.path);
      
      // Handle rejected captures
      if (validationResult['validationStatus'] == AntiCheatService.validationRejected) {
        if (mounted) {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("❌ Capture Rejected"),
              content: Text(
                validationResult['rejectionReason'] ?? 'This capture failed validation checks.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        }
        return; // Exit without saving
      }
      
      // Show warning for flagged captures
      if (validationResult['validationStatus'] == AntiCheatService.validationFlagged) {
        if (mounted) {
          final proceed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("⚠️ Validation Warning"),
              content: const Text(
                'This photo has been flagged during validation. '
                'It may have missing or unusual metadata. '
                'Would you like to proceed anyway?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text("Proceed"),
                ),
              ],
            ),
          );
          if (proceed != true) {
            return; // Exit without saving
          }
        }
      }
    }

    // Location
    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
    final preciseLatitude = pos.latitude;
    final preciseLongitude = pos.longitude;
    final geocell = _geocell(preciseLatitude, preciseLongitude);
    
    // Parse geocell to get coarse coordinates (these are the only ones we save)
    final geocellParts = geocell.split(',');
    final coarseLat = double.parse(geocellParts[0]);
    final coarseLon = double.parse(geocellParts[1]);

    // Identification stub - pass kidsMode to filter species
    final analysis = await ml.analyze(imagePath: file.path, lat: lat, lon: lon, kidsMode: kidsMode);
    // Identification stub (uses precise location for better suggestions, but doesn't save it)
    final analysis = await ml.analyze(imagePath: file.path, lat: preciseLatitude, lon: preciseLongitude);
    final genus = analysis["genus"] as String;
    final candidates = List<Map<String, dynamic>>.from(analysis["species_candidates"]);

    // Build selection UI
    String? species;
    bool speciesConfirmed = false;
    if (candidates.isNotEmpty) {
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text("Species suggestion"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: candidates
                  .map((c) => ListTile(
                        title: Text("${c["species"]}"),
                        subtitle: Text("Confidence ${(c["confidence"] as double).toStringAsFixed(2)}"),
                        onTap: () => Navigator.pop(ctx, c["species"]),
                      ))
                  .toList()
                ..add(ListTile(
                  title: const Text("Keep genus-only"),
                  onTap: () => Navigator.pop(ctx, null),
                )),
            ),
          );
        },
      );
      if (choice != null) {
        species = choice;
        speciesConfirmed = true;
      }
    }

    // Determine group/tier/flags from catalog
    String group = "Unknown";
    String tier = "Common";
    Map<String, bool> flags = {};
    if (species != null) {
      final found = widget.catalogService.findBySpecies(species!);
      if (found != null) {
        group = found["group"];
        final entry = Map<String, dynamic>.from(found["entry"]);
        tier = entry["tier"] ?? "Common";
        flags = Map<String, bool>.from(entry["flags"] ?? {});
      }
    } else {
      final found = widget.catalogService.findByGenus(genus);
      if (found != null) {
        group = found["group"];
        final entry = Map<String, dynamic>.from(found["entry"]);
        tier = entry["tier"] ?? "Common";
        flags = Map<String, bool>.from(entry["flags"] ?? {});
      }
    }

    // Georgia State Species Legendary override handling
    // Task 9: Legendary species get Legendary badge but Epic points if quality < 1.00
    final isStateSpecies = flags["state_species"] == true;
    final qualifiesLegendaryQuality = qMult >= 1.00;
    String pointsTier = tier; // tier used for points calculation
    
    if (isStateSpecies && tier == "Legendary" && !qualifiesLegendaryQuality) {
      // Award Epic points but maintain Legendary badge
      pointsTier = "Epic"; // use Epic tier for points
      // tier stays "Legendary" for badge display
    }

    // Liveness verification for rare/legendary captures (optional)
    bool livenessVerified = false;
    if (LivenessService.isLivenessRequired(tier, enabled: Flags.livenessCheckEnabled)) {
      if (mounted && controller != null) {
        livenessVerified = await LivenessService.verifyLiveness(context, controller!);
        if (!livenessVerified) {
          // User failed or cancelled liveness check
          if (mounted) {
            await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text("❌ Liveness Verification Failed"),
                content: const Text(
                  'Liveness verification is required for rare and legendary captures. '
                  'Please try again.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("OK"),
                  ),
                ],
              ),
            );
          }
          return; // Exit without saving
        }
      }
    }

    // Task 9: Kids Mode - Show safety tips banner for spiders
    if (kidsMode && group != null && (group == "Arachnids – Spiders" || group.toLowerCase().contains("spider"))) {
      if (mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("🛡️ Safety Tip"),
            content: const Text(
              "Great find! Remember to observe spiders from a safe distance. "
              "Never touch spiders with your bare hands. Some spiders can bite if they feel threatened."
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Got it!"),
              ),
            ],
          ),
        );
      }
    }

    final pts = Scoring.points(
      tier: pointsTier,
      qualityMult: qMult,
      speciesConfirmed: speciesConfirmed,
      firstGenus: false, // MVP: no novelty tracking
    );

    debugPrint("Quality: s=$sharpness e=$exposure f=$framing qMult=$qMult");
    debugPrint("Taxon: group=$group genus=$genus species=$species tier=$tier flags=$flags");
    debugPrint("Points: $pts");
    debugPrint("Anti-cheat: status=${validationResult['validationStatus']} hash=${validationResult['photoHash']} hasExif=${validationResult['hasExif']} liveness=$livenessVerified");

    final captureId = const Uuid().v4();
    final captureTimestamp = DateTime.now();

    // Build capture
    // Build capture (only coarse geocell coordinates saved, not precise location)
    final cap = Capture(
      id: captureId,
      photoPath: file.path,
      timestamp: captureTimestamp,
      lat: lat,
      lon: lon,
      timestamp: DateTime.now(),
      lat: coarseLat,  // Coarse coordinate from geocell
      lon: coarseLon,  // Coarse coordinate from geocell
      geocell: geocell,
      group: group,
      genus: genus,
      species: species,
      tier: tier,
      flags: flags,
      points: pts,
      quality: qMult,
      validationStatus: validationResult['validationStatus'],
      photoHash: validationResult['photoHash'],
      hasExif: validationResult['hasExif'],
      livenessVerified: livenessVerified,
    );

    // Mint collectible card
    final card = CardService.mintCard(
      id: captureId,
      userId: "local_user", // MVP: use placeholder user ID
      genus: genus,
      species: species,
      tier: tier,
      quality: qMult,
      timestamp: captureTimestamp,
      geocell: geocell,
      photoPath: file.path,
      flags: flags,
    );

    // Save capture and card
    await JournalPage.saveCapture(cap);
    await CardService.saveCard(card);

    debugPrint("Card minted: rarity=${card.rarity} foil=${card.foil} traits=${card.traits}");

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Saved capture (+$pts pts) • ${card.rarity} card minted!"),
          duration: const Duration(seconds: 3),
        ),
      );
    
    // Check and update quest progress
    final completedQuests = await QuestService.updateProgressForCapture(cap, kidsMode);
    
    if (mounted) {
      String message = "Saved capture (+$pts pts)";
      
      // Show quest completion notification with encouraging message
      if (completedQuests.isNotEmpty) {
        if (completedQuests.length == 1) {
          final quest = completedQuests.first;
          if (kidsMode) {
            message = "🎉 Great job! You completed: ${quest.title}! (+${quest.rewardPoints} pts)";
          } else {
            message += "\n✨ Quest completed: ${quest.title} (+${quest.rewardPoints} pts)";
          }
        } else {
          // Multiple quests completed
          final totalQuestPoints = completedQuests.fold<int>(0, (sum, q) => sum + q.rewardPoints);
          if (kidsMode) {
            message = "🎉 Amazing! You completed ${completedQuests.length} quests! (+$totalQuestPoints pts)";
          } else {
            message += "\n✨ ${completedQuests.length} quests completed! (+$totalQuestPoints pts)";
          }
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _toggleKidsMode(bool newValue) async {
    // If turning OFF Kids Mode, require PIN verification
    if (!newValue && kidsMode) {
      final isPinSetup = await SettingsService.isPinSetup();
      
      if (!isPinSetup) {
        // First time - set up PIN
        if (!mounted) return;
        final pin = await showDialog<String>(
          context: context,
          builder: (ctx) => const PinSetupDialog(),
        );
        
        if (pin == null) return; // User cancelled
        await SettingsService.setPin(pin);
      }
      
      // Verify PIN
      if (!mounted) return;
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Incorrect PIN")),
        );
        return;
      }
    }
    
    // Update Kids Mode
    await SettingsService.setKidsMode(newValue);
    setState(() => kidsMode = newValue);
    
    if (mounted) {
      final message = newValue
          ? "🛡️ Kids Mode enabled - Safe and fun!"
          : "Kids Mode disabled";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    // Update quest progress
    final completedQuests = await QuestService.updateQuestProgress(cap);
    
    // Update streak
    final newStreak = await StreakService.updateStreak();
    
    // Check achievements
    final captures = await JournalPage.loadCaptures();
    final unlockedAchievements = await AchievementService.checkAchievements(captures, newStreak);
    
    if (mounted) {
      String message = "Saved capture (+$pts pts)";
      
      // Add quest completion notifications
      if (completedQuests.isNotEmpty) {
        message += "\n🎯 Quest completed!";
      }
      
      // Add streak notification
      if (newStreak.currentStreak > 1) {
        message += "\n🔥 ${newStreak.currentStreak} day streak!";
      }
      
      // Add achievement notifications
      if (unlockedAchievements.isNotEmpty) {
        message += "\n🏆 Achievement unlocked!";
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Show detailed quest/achievement notifications
      if (completedQuests.isNotEmpty || unlockedAchievements.isNotEmpty) {
        _showRewardsDialog(completedQuests, unlockedAchievements);
      }
    }
  }
  
  void _showRewardsDialog(List<Quest> completedQuests, List<Achievement> achievements) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Rewards!'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (completedQuests.isNotEmpty) ...[
                const Text(
                  'Quests Completed:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...completedQuests.map((q) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('• ${q.title}'),
                )),
                const SizedBox(height: 8),
              ],
              if (achievements.isNotEmpty) ...[
                const Text(
                  'Achievements Unlocked:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...achievements.map((a) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('• ${a.title}'),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!ready) return const Center(child: CircularProgressIndicator());
    return Stack(
      children: [
        CameraPreview(controller!),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FilterChip(
                  label: const Text("Kids Mode"),
                  selected: kidsMode,
                  onSelected: _toggleKidsMode,
                ),
                FloatingActionButton.extended(
                  icon: const Icon(Icons.camera),
                  label: const Text('Capture'),
                  onPressed: _capture,
                ),
              ],
            ),
          ),
        ),
        // Framing overlay - enhanced for Kids Mode
        IgnorePointer(
          child: Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(
                  color: kidsMode
                      ? Colors.yellow.withOpacity(0.9)
                      : Colors.white.withOpacity(0.8),
                  width: kidsMode ? 4 : 2,
                ),
                borderRadius: BorderRadius.circular(kidsMode ? 16 : 8),
              ),
              child: kidsMode
                  ? Stack(
                      children: [
                        // Corner decorations
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Text(
                            "🦋",
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Text(
                            "🐝",
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Text(
                            "🪲",
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Text(
                            "🐞",
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
          ),
        ),
        // Kids Mode encouragement banner
        if (kidsMode)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellow.shade700.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "🌟",
                    style: TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Find a bug and take a photo!",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Text(
                    "🌟",
                    style: TextStyle(fontSize: 24),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}