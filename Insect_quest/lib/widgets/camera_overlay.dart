import 'package:flutter/material.dart';

/// Camera guidance overlay with framing guide and macro tips
class CameraOverlay extends StatelessWidget {
  final bool showTips;
  
  const CameraOverlay({super.key, this.showTips = true});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Framing guide box
        Center(
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
              borderRadius: BorderRadius.circular(8),
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
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Corner guides
    const cornerLength = 20.0;
    
    // Top-left
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLength, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLength), paint);
    
    // Top-right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLength, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), paint);
    
    // Bottom-left
    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerLength), paint);
    
    // Bottom-right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - cornerLength, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLength), paint);

    // Center crosshair
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    const crossSize = 12.0;
    
    canvas.drawLine(
      Offset(centerX - crossSize, centerY), 
      Offset(centerX + crossSize, centerY), 
      paint,
    );
    canvas.drawLine(
      Offset(centerX, centerY - crossSize), 
      Offset(centerX, centerY + crossSize), 
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
          Icon(Icons.lightbulb_outline, color: Colors.amber[300], size: 20),
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
            colors: [Colors.blue[700]!.withOpacity(0.9), Colors.blue[800]!.withOpacity(0.9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              Icon(Icons.child_care, color: Colors.white.withOpacity(0.95), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Kids Mode Active • Safety features enabled',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
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
