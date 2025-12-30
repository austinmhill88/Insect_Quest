import 'dart:math';
import 'package:image/image.dart' as img;

/// Photo quality analysis metrics
class QualityMetrics {
  final double sharpness;
  final double exposure;
  final double framing;

  const QualityMetrics({
    required this.sharpness,
    required this.exposure,
    required this.framing,
  });

  /// Compute quality metrics from an image
  static QualityMetrics analyze(img.Image image) {
    return QualityMetrics(
      sharpness: _computeSharpness(image),
      exposure: _computeExposure(image),
      framing: _computeFraming(image),
    );
  }

  /// Compute sharpness using Laplacian-like measure
  static double _computeSharpness(img.Image im) {
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

  /// Compute exposure via histogram midtone ratio
  static double _computeExposure(img.Image im) {
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

  /// Compute framing heuristic: central crop brightness vs edges
  static double _computeFraming(img.Image im) {
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

  /// Check if quality meets minimum threshold
  bool meetsThreshold(double threshold) {
    return sharpness >= threshold && framing >= threshold;
  }

  @override
  String toString() {
    return 'QualityMetrics(sharpness: ${sharpness.toStringAsFixed(2)}, '
        'exposure: ${exposure.toStringAsFixed(2)}, '
        'framing: ${framing.toStringAsFixed(2)})';
  }
}
