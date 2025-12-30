# Assets Directory

This directory contains placeholder assets for the InsectQuest app.

## Icons

Placeholder icons for camera overlays and UI elements:
- `camera_guide.txt` - Placeholder for camera framing guide icon
- `macro_tips.txt` - Placeholder for macro photography tips icon
- `kids_mode.txt` - Placeholder for Kids Mode safety icon
- `safety_warning.txt` - Placeholder for safety warning icons

## Future Assets

When ready to replace placeholders with actual assets:
1. Replace `.txt` files with proper image formats (PNG, SVG)
2. Use recommended sizes:
   - Icons: 24x24dp, 48x48dp (ldpi, mdpi, hdpi, xhdpi, xxhdpi)
   - Overlays: Vector format (SVG) for scalability
3. Update `pubspec.yaml` to include new asset paths
4. Update widget references to use new asset paths

## Overlay Design Guidelines

- Use white/semi-transparent colors for camera overlays
- Keep overlay elements minimal to avoid obscuring the camera view
- Test overlays in both bright and dark conditions
- Ensure Kids Mode overlays are child-friendly and clear

## Asset Sources

Consider using:
- Material Icons: https://fonts.google.com/icons
- Flutter's built-in icon library
- Custom illustrations for unique branding
