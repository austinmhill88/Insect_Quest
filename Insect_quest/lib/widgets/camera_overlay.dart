import 'package:flutter/material.dart';

/// Camera guidance overlay with framing guide and macro tips
class CameraOverlay extends StatelessWidget {
  // Framing guide dimensions
  static const double _guideWidth = 240.0;
  static const double _guideHeight = 240.0;
  static const double _guideBorderWidth = 2.0;
  static const double _guideBorderRadius = 8.0;
  
  final bool showTips;
  
  const CameraOverlay({super.key, this.showTips = true});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Framing guide box
        Center(
          child: Container(
            width: _guideWidth,
            height: _guideHeight,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withOpacity(0.8), width: _guideBorderWidth),
              borderRadius: BorderRadius.circular(_guideBorderRadius),
            ),
            child: CustomPaint(
              painter: _FramingGuidePainter(),
            ),
          ),
        ),
        // Macro tips at top
        if (showTips)
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: _MacroTipsCard(),
          ),
      ],
    );
  }
}

/// Paints corner guides and center cross
class _FramingGuidePainter extends CustomPainter {
  // Guide element dimensions
  static const double _cornerLength = 20.0;
  static const double _crossSize = 12.0;
  static const double _strokeWidth = 1.5;
  static const double _guideOpacity = 0.6;
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(_guideOpacity)
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke;

    // Corner guides - Top-left
    canvas.drawLine(const Offset(0, 0), const Offset(_cornerLength, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, _cornerLength), paint);
    
    // Top-right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - _cornerLength, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, _cornerLength), paint);
    
    // Bottom-left
    canvas.drawLine(Offset(0, size.height), Offset(_cornerLength, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - _cornerLength), paint);
    
    // Bottom-right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - _cornerLength, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - _cornerLength), paint);

    // Center crosshair
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    canvas.drawLine(
      Offset(centerX - _crossSize, centerY), 
      Offset(centerX + _crossSize, centerY), 
      paint,
    );
    canvas.drawLine(
      Offset(centerX, centerY - _crossSize), 
      Offset(centerX, centerY + _crossSize), 
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Macro photography tips card
class _MacroTipsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lightbulb_outline, color: Colors.amber.shade300, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Keep subject centered • Hold steady • Get close',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kids Mode safety banner overlay
class KidsModeBanner extends StatelessWidget {
  static const double _bannerOpacity = 0.95;
  
  const KidsModeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade700.withOpacity(0.9),
              Colors.blue.shade800.withOpacity(0.9),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              Icon(Icons.child_care, color: Colors.white.withOpacity(_bannerOpacity), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Kids Mode Active • Safety features enabled',
                  style: TextStyle(
                    color: Colors.white.withOpacity(_bannerOpacity),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
