# Camera UX Enhancement Documentation

This document describes the modular camera experience implementation for easy future enhancements and art asset swaps.

## Architecture Overview

The camera experience is now organized into modular, reusable components:

### 1. Quality Analysis Module
**File:** `lib/models/quality_metrics.dart`

The `QualityMetrics` class encapsulates all photo quality analysis:
- **Sharpness**: Laplacian-based focus detection (40% weight)
- **Exposure**: Histogram midtone ratio (20% weight)  
- **Framing**: Center vs edge brightness ratio (40% weight)

**Benefits:**
- Isolated, testable quality analysis logic
- Easy to adjust thresholds or add new metrics
- Clean API: `QualityMetrics.analyze(image)`

**Usage:**
```dart
final metrics = QualityMetrics.analyze(image);
if (metrics.meetsThreshold(0.9)) {
  // Quality is acceptable
}
```

### 2. Camera Overlay Widgets
**File:** `lib/widgets/camera_overlay.dart`

Three modular overlay components:

#### `CameraOverlay`
- Framing guide with corner markers
- Center crosshair for alignment
- Macro photography tips card
- `showTips` parameter to toggle tip visibility

#### `KidsModeBanner`
- Prominent safety banner for Kids Mode
- Shows at top of camera screen
- Blue gradient design for visibility
- Child-friendly messaging

#### `_FramingGuidePainter`
- Custom painter for camera guides
- Draws corner L-shapes and center cross
- Semi-transparent white for visibility

**Benefits:**
- Overlays can be enabled/disabled independently
- Easy to swap in custom designs
- Consistent styling across app

### 3. Camera Page Integration
**File:** `lib/pages/camera_page.dart`

The camera page now:
- Uses `QualityMetrics` for analysis (replaces inline calculations)
- Shows enhanced `CameraOverlay` with guidance
- Displays `KidsModeBanner` when Kids Mode is active
- Implements safety prompts for both spiders AND centipedes

## Features Implemented

### ✅ Guided Overlays
- Corner guides and center crosshair for framing
- Macro tips card with photography advice
- Semi-transparent design doesn't obscure view

### ✅ Quality Analysis
- Modular `QualityMetrics` class
- Computes sharpness, exposure, framing
- Triggers retake prompt if quality < 0.9
- Kids Mode enforces 0.9 minimum quality floor

### ✅ Kids Mode Enhancements
- Prominent banner overlay at top of camera
- Minimum quality enforcement (0.9 floor)
- Safety prompts for spiders
- Safety prompts for centipedes (NEW)
- Visual indicators throughout experience

### ✅ Placeholder Assets
- Created `assets/icons/` directory
- Placeholder files for future art assets
- README with design guidelines
- Uses Flutter Material Icons for MVP

## Acceptance Criteria Status

✅ **User sees guided overlays in camera**
- Corner guides, center crosshair, and macro tips visible
- Kids Mode banner shows when active

✅ **Photo analyzed for quality; retake prompt if below threshold**
- `QualityMetrics.analyze()` computes metrics
- Retake dialog shown if `meetsThreshold(0.9)` returns false
- User can choose to keep or retake

✅ **Kids Mode disables low-quality submissions**
- Quality floor enforced at 0.9 in `Scoring.qualityMultiplier()`
- Retake prompt appears more frequently

✅ **Kids Mode shows safety banner and prompts**
- Banner overlay at top of camera screen
- Safety prompts for spiders
- Safety prompts for centipedes

✅ **Code is modular for art swap and enhancements**
- Separate `QualityMetrics` class
- Reusable overlay widgets in `lib/widgets/`
- Easy to replace placeholder assets
- Clean separation of concerns

## Future Enhancements

### Art Asset Swaps
To replace placeholder assets with custom artwork:

1. **Create assets** in appropriate formats:
   - PNG for raster graphics (24x24dp, 48x48dp)
   - SVG for vector graphics (recommended for overlays)

2. **Add to `assets/icons/`** directory:
   - Replace `.txt` placeholders
   - Keep filenames consistent or update references

3. **Update `pubspec.yaml`** if needed:
   ```yaml
   assets:
     - assets/icons/camera_guide.png
     - assets/icons/macro_tips.png
   ```

4. **Update widget references**:
   ```dart
   // In camera_overlay.dart
   Image.asset('assets/icons/macro_tips.png', width: 20, height: 20)
   ```

### Additional Quality Metrics
To add new quality metrics:

1. **Add method to `QualityMetrics` class**:
   ```dart
   static double _computeContrast(img.Image im) {
     // Implementation
   }
   ```

2. **Include in `analyze()` method**:
   ```dart
   return QualityMetrics(
     sharpness: _computeSharpness(image),
     exposure: _computeExposure(image),
     framing: _computeFraming(image),
     contrast: _computeContrast(image), // NEW
   );
   ```

3. **Update scoring weights** in `config/scoring.dart`

### Custom Overlay Designs
To create custom camera overlays:

1. **Extend or replace `CameraOverlay`**:
   ```dart
   class PremiumCameraOverlay extends CameraOverlay {
     // Custom design
   }
   ```

2. **Use in `camera_page.dart`**:
   ```dart
   IgnorePointer(
     child: PremiumCameraOverlay(showTips: true),
   )
   ```

### Animated Overlays
To add animations:

1. **Make overlay stateful**:
   ```dart
   class AnimatedCameraOverlay extends StatefulWidget {
     // Animation controller
   }
   ```

2. **Add animation to painter or widgets**
3. **Update camera page to use animated version**

## Testing Recommendations

When testing the camera experience:

1. **Test quality thresholds**
   - Capture clear, sharp photos (should pass)
   - Capture blurry photos (should prompt retake)
   - Verify Kids Mode enforces 0.9 minimum

2. **Test overlays**
   - Verify corner guides are visible
   - Check macro tips card displays
   - Confirm Kids Mode banner shows

3. **Test safety prompts**
   - Capture spider in Kids Mode → safety dialog
   - Capture centipede in Kids Mode → safety dialog
   - Verify correct messages for each type

4. **Test Kids Mode toggle**
   - Toggle on/off updates banner visibility
   - Quality floor applied correctly
   - Settings persist across app restarts

## Code Quality Notes

- **No breaking changes**: Existing functionality preserved
- **Modular design**: Easy to extend and test
- **Consistent styling**: Follows Material Design
- **Performance**: Quality analysis optimized (sampled pixels)
- **Accessibility**: High contrast overlays for visibility

## Related Files

- `lib/pages/camera_page.dart` - Main camera UI
- `lib/models/quality_metrics.dart` - Quality analysis logic
- `lib/widgets/camera_overlay.dart` - Overlay components
- `lib/config/scoring.dart` - Scoring and quality multipliers
- `assets/icons/` - Placeholder assets and guidelines
- `pubspec.yaml` - Asset declarations

---

**Implementation Date:** December 2024  
**Status:** ✅ Complete and Ready for Production
