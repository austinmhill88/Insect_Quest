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
import '../models/genus_suggestion.dart';
import '../services/identifier_service.dart';
import '../services/catalog_service.dart';
import '../services/settings_service.dart';
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

    // Location
    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
    final lat = pos.latitude;
    final lon = pos.longitude;
    final geocell = _geocell(lat, lon);

    // Genus-first identification
    final genusSuggestions = await identifier.identifyGenus(
      imagePath: file.path,
      lat: lat,
      lon: lon,
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

    // Build capture
    final cap = Capture(
      id: const Uuid().v4(),
      photoPath: file.path,
      timestamp: DateTime.now(),
      lat: lat,
      lon: lon,
      geocell: geocell,
      group: group,
      genus: genus,
      species: species,
      tier: tier,
      flags: flags,
      points: pts,
      quality: qMult,
    );

    // Save and navigate to Journal
    await JournalPage.saveCapture(cap);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Saved capture (+$pts pts)")));
    }
  }

  /// Show genus suggestions dialog
  /// 
  /// Displays 3-5 genus suggestions from the identifier service.
  /// User can select a genus, manually enter one, or cancel.
  Future<GenusSuggestion?> _showGenusSuggestionsDialog(List<GenusSuggestion> suggestions) async {
    // Signal value for manual entry
    final manualEntrySignal = GenusSuggestion(
      genus: '__MANUAL_ENTRY__',
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
    if (result != null && result.genus == '__MANUAL_ENTRY__') {
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
                  onSelected: (v) async {
                    await SettingsService.setKidsMode(v);
                    setState(() => kidsMode = v);
                  },
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
        // Simple framing overlay
        IgnorePointer(
          child: Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}