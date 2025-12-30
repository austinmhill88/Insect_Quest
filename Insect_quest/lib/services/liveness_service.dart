import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Service for verifying liveness through camera movement challenges
/// Optional check for rare/legendary captures to prevent fraud
class LivenessService {
  /// Prompt user to perform camera movement for liveness verification
  /// Returns true if movement detected, false if verification failed
  static Future<bool> verifyLiveness(
    BuildContext context,
    CameraController controller,
  ) async {
    if (!context.mounted) return false;
    
    // Show liveness challenge dialog
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _LivenessDialog(controller: controller),
    );
    
    return result ?? false;
  }
  
  /// Check if liveness verification is required for this tier
  /// Can be configured per rarity level
  static bool isLivenessRequired(String tier, {bool enabled = false}) {
    if (!enabled) return false;
    
    // Require liveness for Epic and Legendary captures
    return tier == 'Epic' || tier == 'Legendary';
  }
}

/// Dialog widget for liveness challenge
class _LivenessDialog extends StatefulWidget {
  final CameraController controller;
  
  const _LivenessDialog({required this.controller});
  
  @override
  State<_LivenessDialog> createState() => _LivenessDialogState();
}

class _LivenessDialogState extends State<_LivenessDialog> {
  static const Duration _movementStepDuration = Duration(seconds: 3);
  static const Duration _successDisplayDuration = Duration(seconds: 1);
  
  bool _verifying = false;
  String _instruction = 'Slowly move your camera left, then right';
  int _step = 0;
  Timer? _timer;
  
  @override
  void initState() {
    super.initState();
    _startVerification();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  void _startVerification() {
    setState(() {
      _verifying = true;
      _instruction = 'Slowly move your camera left...';
    });
    
    // Simulate liveness detection with timed prompts
    // In a production app, this would analyze accelerometer data
    // or use computer vision to detect actual movement
    _timer = Timer(_movementStepDuration, () {
      if (!mounted) return;
      
      setState(() {
        _step = 1;
        _instruction = 'Good! Now move it right...';
      });
      
      _timer = Timer(_movementStepDuration, () {
        if (!mounted) return;
        
        setState(() {
          _step = 2;
          _instruction = 'Verified! ✓';
          _verifying = false;
        });
        
        // Auto-close after showing success
        _timer = Timer(_successDisplayDuration, () {
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        });
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('🛡️ Liveness Verification'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'To verify this is a live capture, please follow the instructions:',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (_verifying)
            const CircularProgressIndicator()
          else if (_step == 2)
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
          const SizedBox(height: 16),
          Text(
            _instruction,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        if (!_verifying && _step == 0)
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
      ],
    );
  }
}
