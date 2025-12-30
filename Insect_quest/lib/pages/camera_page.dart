import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';
import '../config/scoring.dart';
import '../config/feature_flags.dart';
import '../models/capture.dart';
import '../models/quality_metrics.dart';
import '../services/ml_stub.dart';
import '../services/catalog_service.dart';
import '../services/settings_service.dart';
import '../widgets/camera_overlay.dart';
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

    // Location
    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
    final lat = pos.latitude;
    final lon = pos.longitude;
    final geocell = _geocell(lat, lon);

    // Identification stub
    final analysis = await ml.analyze(imagePath: file.path, lat: lat, lon: lon);
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

    final pts = Scoring.points(
      tier: pointsTier,
      qualityMult: qMult,
      speciesConfirmed: speciesConfirmed,
      firstGenus: false, // MVP: no novelty tracking
    );

    debugPrint("Quality: ${metrics.toString()} qMult=$qMult");
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
      ],
    );
  }
}