# Identifier Service Documentation

## Overview

The `IdentifierService` implements a genus-first identification approach for insect and arthropod recognition. This service is designed to work with on-device machine learning models (TFLite) with fallback support for cloud-based classification.

## Current Implementation: Stub/Placeholder

The current implementation uses heuristic-based logic to simulate ML inference:
- Location-based filtering (prefers Georgia state species when in-state)
- Random selection from species catalog
- Simulated confidence scores

**This is intentional for MVP development.** The stub allows the app to be fully functional while ML models are being trained or evaluated.

## Integration Flow

### User Experience Flow

1. **Photo Capture** → User takes photo with camera
2. **Genus Suggestions** → Service returns 3-5 plausible genera
3. **Genus Selection** → User selects genus or enters manually
4. **Species Input** (Optional) → User can specify species or keep genus-only
5. **Card Minting** → Capture is saved to journal with points awarded

### Code Flow

```dart
// In camera_page.dart
final genusSuggestions = await identifier.identifyGenus(
  imagePath: file.path,
  lat: lat,
  lon: lon,
  kidsMode: kidsMode,
);

// Show genus dialog
final selectedGenus = await _showGenusSuggestionsDialog(genusSuggestions);

// Optionally get species
final species = await _showSpeciesInputDialog(selectedGenus.genus);

// Mint capture
final capture = Capture(...);
await JournalPage.saveCapture(capture);
```

## Replacing with Real ML Model

### Option 1: On-Device TFLite Model

#### Step 1: Prepare Your Model

1. Train a genus classification model (e.g., using TensorFlow, PyTorch)
2. Convert to TFLite format
3. Optimize for mobile (quantization recommended)
4. Test inference speed (target: <2s per image)

#### Step 2: Add Model to Project

```yaml
# pubspec.yaml
flutter:
  assets:
    - assets/models/genus_classifier.tflite
    - assets/models/label_map.json
```

#### Step 3: Replace Stub Implementation

```dart
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:typed_data';

class IdentifierService {
  Interpreter? _interpreter;
  List<String>? _labels;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('models/genus_classifier.tflite');
    final labelsJson = await rootBundle.loadString('assets/models/label_map.json');
    _labels = jsonDecode(labelsJson)['labels'];
  }

  Future<List<GenusSuggestion>> identifyGenus({
    required String imagePath,
    required double lat,
    required double lon,
    required bool kidsMode,
  }) async {
    // Preprocess image
    final input = await _preprocessImage(imagePath);
    
    // Run inference
    final output = List.filled(_labels!.length, 0.0).reshape([1, _labels!.length]);
    _interpreter!.run(input, output);
    
    // Parse results
    final suggestions = _parseOutput(output[0], lat, lon);
    
    // Apply Kids Mode filtering
    if (kidsMode) {
      return _filterForKidsMode(suggestions);
    }
    
    return suggestions;
  }

  Future<List<List<List<List<double>>>>> _preprocessImage(String imagePath) async {
    // Load image
    final bytes = await File(imagePath).readAsBytes();
    final image = img.decodeImage(bytes)!;
    
    // Resize to model input size (e.g., 224x224)
    final resized = img.copyResize(image, width: 224, height: 224);
    
    // Normalize pixel values to [0, 1] or [-1, 1] depending on your model
    final input = List.generate(
      1,
      (batch) => List.generate(
        224,
        (y) => List.generate(
          224,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              img.getRed(pixel) / 255.0,
              img.getGreen(pixel) / 255.0,
              img.getBlue(pixel) / 255.0,
            ];
          },
        ),
      ),
    );
    
    return input;
  }

  List<GenusSuggestion> _parseOutput(List<double> confidences, double lat, double lon) {
    // Create list of (genus, confidence) pairs
    final pairs = <MapEntry<String, double>>[];
    for (int i = 0; i < _labels!.length; i++) {
      pairs.add(MapEntry(_labels![i], confidences[i]));
    }
    
    // Sort by confidence (descending)
    pairs.sort((a, b) => b.value.compareTo(a.value));
    
    // Take top 3-5
    final topPairs = pairs.take(5);
    
    // Convert to GenusSuggestion objects
    return topPairs.map((pair) {
      final catalogEntry = catalogService.findByGenus(pair.key);
      return GenusSuggestion(
        genus: pair.key,
        confidence: pair.value,
        commonName: catalogEntry?['entry']['common'],
        group: catalogEntry?['group'],
      );
    }).toList();
  }
}
```

### Option 2: Cloud Classifier Fallback

#### Architecture

```
Mobile App
    │
    ├─── Try On-Device First (fast)
    │    └─── If confidence < 0.5, try cloud
    │
    └─── Cloud Classifier API
         ├─── Higher accuracy models
         ├─── Larger model size allowed
         └─── Returns genus + confidence
```

#### Implementation

```dart
Future<List<GenusSuggestion>> identifyGenus({
  required String imagePath,
  required double lat,
  required double lon,
  required bool kidsMode,
}) async {
  // Try on-device first
  List<GenusSuggestion> suggestions = await _identifyOnDevice(imagePath);
  
  // If low confidence, try cloud fallback
  if (suggestions.isEmpty || suggestions.first.confidence < 0.5) {
    try {
      final cloudSuggestions = await _identifyViaCloud(imagePath, lat, lon);
      if (cloudSuggestions.isNotEmpty) {
        suggestions = cloudSuggestions;
      }
    } catch (e) {
      debugPrint('Cloud identification failed: $e');
      // Continue with on-device results
    }
  }
  
  // Apply Kids Mode filtering
  if (kidsMode) {
    suggestions = _filterForKidsMode(suggestions);
  }
  
  return suggestions;
}

Future<List<GenusSuggestion>> _identifyViaCloud(
  String imagePath,
  double lat,
  double lon,
) async {
  final bytes = await File(imagePath).readAsBytes();
  final base64Image = base64Encode(bytes);
  
  final response = await http.post(
    Uri.parse('https://your-api.com/v1/identify'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${await _getApiToken()}',
    },
    body: jsonEncode({
      'image': base64Image,
      'lat': lat,
      'lon': lon,
      'version': 'v1',
    }),
  );
  
  if (response.statusCode != 200) {
    throw Exception('Cloud API error: ${response.statusCode}');
  }
  
  final data = jsonDecode(response.body);
  final predictions = data['predictions'] as List;
  
  return predictions.map((p) => GenusSuggestion(
    genus: p['genus'],
    confidence: p['confidence'],
    commonName: p['commonName'],
    group: p['group'],
  )).toList();
}
```

### Option 3: Hybrid Approach (Recommended)

```dart
Future<List<GenusSuggestion>> identifyGenus({
  required String imagePath,
  required double lat,
  required double lon,
  required bool kidsMode,
}) async {
  List<GenusSuggestion> suggestions = [];
  
  // Check connectivity
  final hasInternet = await _checkConnectivity();
  
  if (hasInternet) {
    // Cloud-first for best accuracy
    try {
      suggestions = await _identifyViaCloud(imagePath, lat, lon);
    } catch (e) {
      debugPrint('Cloud failed, falling back to on-device: $e');
      suggestions = await _identifyOnDevice(imagePath);
    }
  } else {
    // On-device when offline
    suggestions = await _identifyOnDevice(imagePath);
  }
  
  // Apply Kids Mode filtering
  if (kidsMode) {
    suggestions = _filterForKidsMode(suggestions);
  }
  
  return suggestions;
}
```

## Kids Mode Safety Filtering

The service automatically filters unsafe genera when Kids Mode is enabled.

### Currently Filtered Genera

- **Spiders**: `Phidippus`, `Argiope`, `Trichonephila`
- **Centipedes**: `Scutigera`

### Filtered Groups

- `Arachnids – Spiders`
- `Myriapods – Centipedes`

### Updating Filter Lists

To add or remove filtered genera, edit the constants in `identifier_service.dart`:

```dart
static const List<String> _unsafeGeneraForKids = [
  'Phidippus',
  'Argiope',
  'Trichonephila',
  'Scutigera',
  // Add more here
];

static const List<String> _unsafeGroupsForKids = [
  'Arachnids – Spiders',
  'Myriapods – Centipedes',
  // Add more here
];
```

## Model Training Recommendations

### Dataset Requirements

- **Minimum samples per genus**: 100-200 images
- **Variety**: Different angles, lighting, backgrounds
- **Location metadata**: Include GPS coordinates for location bias
- **Balanced classes**: Equal representation of common genera

### Model Architecture Suggestions

- **MobileNetV3** - Fast, efficient, good baseline
- **EfficientNet-Lite** - Better accuracy, slightly slower
- **Custom CNN** - If you have specific requirements

### Training Tips

1. **Data augmentation**: Rotation, flip, brightness, crop
2. **Transfer learning**: Start from ImageNet weights
3. **Location features**: Include lat/lon as additional inputs
4. **Multi-task learning**: Train genus + species simultaneously
5. **Quantization**: Post-training quantization for smaller model size

### Evaluation Metrics

- **Top-1 Accuracy**: Primary genus prediction correct
- **Top-3 Accuracy**: Correct genus in top 3 suggestions (target: >90%)
- **Top-5 Accuracy**: Correct genus in top 5 suggestions (target: >95%)
- **Inference Time**: <2 seconds on mid-range Android device

## API Specification (Cloud Fallback)

### Endpoint: POST /v1/identify

**Request:**
```json
{
  "image": "base64_encoded_image_data",
  "lat": 34.0,
  "lon": -84.0,
  "version": "v1",
  "client_version": "0.1.0"
}
```

**Response:**
```json
{
  "predictions": [
    {
      "genus": "Papilio",
      "confidence": 0.89,
      "commonName": "Swallowtail Butterflies",
      "group": "Butterflies"
    },
    {
      "genus": "Apis",
      "confidence": 0.67,
      "commonName": "Honey Bees",
      "group": "Bees/Wasps"
    }
  ],
  "model_version": "genus-classifier-v2.1",
  "inference_time_ms": 156
}
```

**Error Response:**
```json
{
  "error": "invalid_image",
  "message": "Image format not supported",
  "code": 400
}
```

## Testing Your Model Integration

### Unit Tests

```dart
void main() {
  group('IdentifierService', () {
    test('returns 3-5 genus suggestions', () async {
      final service = IdentifierService(catalogService: mockCatalog);
      final suggestions = await service.identifyGenus(
        imagePath: 'test_image.jpg',
        lat: 34.0,
        lon: -84.0,
        kidsMode: false,
      );
      expect(suggestions.length, greaterThanOrEqualTo(3));
      expect(suggestions.length, lessThanOrEqualTo(5));
    });

    test('filters unsafe genera in Kids Mode', () async {
      final service = IdentifierService(catalogService: mockCatalog);
      final suggestions = await service.identifyGenus(
        imagePath: 'test_image.jpg',
        lat: 34.0,
        lon: -84.0,
        kidsMode: true,
      );
      
      for (final suggestion in suggestions) {
        expect(suggestion.genus, isNot(equals('Phidippus')));
        expect(suggestion.genus, isNot(equals('Argiope')));
        expect(suggestion.genus, isNot(equals('Trichonephila')));
      }
    });
  });
}
```

### Manual Testing Checklist

- [ ] Take photo of butterfly → Verify 3-5 genus suggestions appear
- [ ] Select a genus → Verify species dialog appears
- [ ] Enter manual genus → Verify custom input works
- [ ] Enable Kids Mode → Verify spider genera are filtered
- [ ] Test in Georgia → Verify state species are prioritized
- [ ] Test offline → Verify on-device model works
- [ ] Test online → Verify cloud fallback works (if implemented)
- [ ] Measure inference time → Should be <2 seconds

## Performance Optimization

### On-Device Model

- **Model size**: <10MB for TFLite (quantized)
- **Input size**: 224x224 recommended (balance of speed/accuracy)
- **Quantization**: INT8 quantization reduces size by 4x
- **Delegates**: Use GPU delegate on supported devices

### Cloud API

- **Image compression**: Compress to 800x800 before upload
- **Caching**: Cache cloud results by geocell for 24 hours
- **Batching**: Consider batch API if capturing multiple photos
- **Timeout**: Set 10-second timeout for cloud requests

## Future Enhancements

### Short Term
- [ ] Add confidence threshold tuning
- [ ] Implement result caching
- [ ] Add telemetry for model performance

### Long Term
- [ ] Multi-model ensemble
- [ ] User feedback loop for retraining
- [ ] Species-level identification
- [ ] Real-time video identification
- [ ] Offline model updates via app updates

## Support and Troubleshooting

### Common Issues

**Issue**: Model inference is slow (>5 seconds)
- **Solution**: Reduce input size, use quantized model, enable GPU delegate

**Issue**: Low accuracy on common insects
- **Solution**: Add more training data, use data augmentation, try transfer learning

**Issue**: Cloud API fails frequently
- **Solution**: Add retry logic, increase timeout, implement better error handling

**Issue**: Kids Mode filters too many results
- **Solution**: Adjust `_unsafeGeneraForKids` list, ensure at least 3 safe genera in catalog

## Contact

For questions about ML model integration, contact the development team or file an issue on GitHub.
