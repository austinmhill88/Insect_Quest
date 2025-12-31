import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';
import '../config/scoring.dart';
import '../config/feature_flags.dart';
import '../models/capture.dart';
import '../models/genus_suggestion.dart';
import '../services/identifier_service.dart';
import '../models/quality_metrics.dart';
import '../services/ml_stub.dart';
import '../services/catalog_service.dart';
import '../services/settings_service.dart';
import '../services/firestore_service.dart';
import '../services/user_service.dart';
import '../widgets/camera_overlay.dart';
import '../models/arthropod_card.dart';
import '../services/card_service.dart';
import '../models/quest.dart';
import '../models/achievement.dart';
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
  late final IdentifierService identifier;
  bool kidsMode = Flags.kidsModeDefault;

  @override
  void initState() {
    super.initState();
    identifier = IdentifierService(catalogService: widget.catalogService);
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

    // Quality analysis using modular QualityMetrics
    final metrics = QualityMetrics.analyze(im);
    final qMult = Scoring.qualityMultiplier(
      sharpness: metrics.sharpness,
      exposure: metrics.exposure,
      framing: metrics.framing,
      kidsMode: kidsMode,
    );

    // Retake prompt for low-quality shots
    if (!metrics.meetsThreshold(0.9)) {
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

    // Genus-first identification
    final genusSuggestions = await identifier.identifyGenus(
      imagePath: file.path,
      lat: preciseLatitude,
      lon: preciseLongitude,
      kidsMode: kidsMode,
    );

    if (!mounted) return;

    // Step 1: Show genus suggestions (3-5 options)
    final selectedGenus = await _showGenusSuggestionsDialog(genusSuggestions);
    if (selectedGenus == null) {
      // User cancelled
      return;
    }

    // Step 2: Allow user to optionally specify species or keep genus-only
    String genus = selectedGenus.genus;
    String? species;
    bool speciesConfirmed = false;

    if (!mounted) return;
    
    final speciesChoice = await _showSpeciesInputDialog(genus);
    if (speciesChoice != null && speciesChoice.isNotEmpty) {
      species = speciesChoice;
      speciesConfirmed = true;
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

    // Safety tips for spiders and centipedes in Kids Mode
    if (kidsMode && group != null) {
      bool showSafetyTip = false;
      String safetyMessage = "";
      
      if (group == "Arachnids – Spiders" || group.toLowerCase().contains("spider")) {
        showSafetyTip = true;
        safetyMessage = "Great find! Remember to observe spiders from a safe distance. "
            "Never touch spiders with your bare hands. Some spiders can bite if they feel threatened.";
      } else if (group == "Myriapods – Centipedes" || group.toLowerCase().contains("centipede")) {
        showSafetyTip = true;
        safetyMessage = "Great find! Remember to observe centipedes from a safe distance. "
            "Never touch centipedes with your bare hands. Centipedes can bite and may cause irritation.";
      }
      
      if (showSafetyTip && mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("🛡️ Safety Tip"),
            content: Text(safetyMessage),
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

    final pts = Scoring.points(
      tier: pointsTier,
      qualityMult: qMult,
      speciesConfirmed: speciesConfirmed,
      firstGenus: false, // MVP: no novelty tracking
    );

    // Calculate coins awarded for minting this card
    final coinsAwarded = Scoring.coins(
      tier: pointsTier,
      qualityMult: qMult,
    ).clamp(0, 10000); // Validate reasonable bounds (0-10k coins per capture)

    debugPrint("Quality: ${metrics.toString()} qMult=$qMult");
    debugPrint("Taxon: group=$group genus=$genus species=$species tier=$tier flags=$flags");
    debugPrint("Points: $pts, Coins: $coinsAwarded");
    debugPrint("Anti-cheat: status=${validationResult['validationStatus']} hash=${validationResult['photoHash']} hasExif=${validationResult['hasExif']} liveness=$livenessVerified");

    final captureId = const Uuid().v4();
    final captureTimestamp = DateTime.now();

    // Build capture (only coarse geocell coordinates saved, not precise location)
    final cap = Capture(
      id: captureId,
      photoPath: file.path,
      timestamp: captureTimestamp,
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
      coins: coinsAwarded,
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

    // Award coins and sync to Firestore
    try {
      final userId = await UserService.getUserId();
      final firestoreService = FirestoreService();
      await firestoreService.addCoins(userId, coinsAwarded);
    } catch (e) {
      debugPrint("Error syncing coins to Firestore: $e");
      // Continue even if Firestore sync fails (coins are still tracked locally)
    }
    
    // Check and update quest progress
    final completedQuests = await QuestService.updateProgressForCapture(cap, kidsMode);
    
    if (mounted) {
      String message = "Saved capture (+$pts pts, +$coinsAwarded coins) • ${card.rarity} card minted!";
      
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

  /// Show genus suggestions dialog
  /// 
  /// Displays 3-5 genus suggestions from the identifier service.
  /// User can select a genus, manually enter one, or cancel.
  Future<GenusSuggestion?> _showGenusSuggestionsDialog(List<GenusSuggestion> suggestions) async {
    // Signal value for manual entry
    final manualEntrySignal = GenusSuggestion(
      genus: GenusSuggestion.manualEntrySignal,
      confidence: 0.0,
    );
    
    final result = await showDialog<GenusSuggestion>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("What did you find?"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Select the genus that best matches your observation:",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                ...suggestions.map((suggestion) => ListTile(
                      title: Text(
                        suggestion.genus,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (suggestion.commonName != null)
                            Text(suggestion.commonName!),
                          Text(
                            "Confidence: ${(suggestion.confidence * 100).toStringAsFixed(0)}%",
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      leading: CircleAvatar(
                        child: Text("${(suggestion.confidence * 100).toInt()}"),
                      ),
                      onTap: () => Navigator.pop(ctx, suggestion),
                    )),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text("Enter genus manually"),
                  onTap: () => Navigator.pop(ctx, manualEntrySignal),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
    
    // If user chose manual entry, show manual input dialog
    if (result != null && result.isManualEntrySignal) {
      return await _showManualGenusInputDialog();
    }
    
    return result;
  }

  /// Show manual genus input dialog
  Future<GenusSuggestion?> _showManualGenusInputDialog() async {
    final controller = TextEditingController();
    return showDialog<GenusSuggestion>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Enter Genus"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: "Genus name",
              hintText: "e.g., Papilio",
            ),
            textCapitalization: TextCapitalization.words,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                final genus = controller.text.trim();
                if (genus.isNotEmpty) {
                  Navigator.pop(
                    ctx,
                    GenusSuggestion(
                      genus: genus,
                      confidence: 1.0, // User override
                      commonName: null,
                      group: null,
                    ),
                  );
                }
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  /// Show species input dialog
  /// 
  /// Allows user to optionally specify species or keep genus-only.
  /// Shows species suggestions if available in catalog for the genus.
  Future<String?> _showSpeciesInputDialog(String genus) async {
    // Get species suggestions for this genus from catalog
    final speciesSuggestions = identifier.getSpeciesSuggestionsForGenus(genus);
    
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        final manualController = TextEditingController();
        return AlertDialog(
          title: Text("Species for $genus?"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "You can specify the species or keep genus-only:",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: const Text("Keep genus-only"),
                  subtitle: Text("Save as $genus"),
                  onTap: () => Navigator.pop(ctx, null),
                ),
                if (speciesSuggestions.isNotEmpty) ...[
                  const Divider(),
                  const Text(
                    "Or select a known species:",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  ...speciesSuggestions.map((species) => ListTile(
                        title: Text(species),
                        onTap: () => Navigator.pop(ctx, species),
                      )),
                ],
                const Divider(),
                TextField(
                  controller: manualController,
                  decoration: const InputDecoration(
                    labelText: "Or enter species manually",
                    hintText: "e.g., Papilio glaucus",
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text("Keep genus-only"),
            ),
            TextButton(
              onPressed: () {
                final species = manualController.text.trim();
                if (species.isNotEmpty) {
                  Navigator.pop(ctx, species);
                }
              },
              child: const Text("Confirm species"),
            ),
          ],
        );
      },
    );
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
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ready) return const Center(child: CircularProgressIndicator());
    return Stack(
      children: [
        CameraPreview(controller!),
        // Kids Mode banner
        if (kidsMode) const KidsModeBanner(),
        // Enhanced camera overlay with guidance
        IgnorePointer(
          child: CameraOverlay(showTips: true),
        ),
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