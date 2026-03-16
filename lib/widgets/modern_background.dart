import 'dart:math' as math;
import 'package:flutter/material.dart';

class ModernBackground extends StatefulWidget {
  const ModernBackground({super.key, required this.child});

  final Widget child;

  @override
  State<ModernBackground> createState() => _ModernBackgroundState();
}

class _ModernBackgroundState extends State<ModernBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base Gradient
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF1F8E9),
                  Color(0xFFF9FBE7),
                  Color(0xFFE8F5E9),
                ],
              ),
            ),
          ),
        ),
        // Animated Blobs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: [
                _buildBlob(
                  color: const Color(0xFFC8E6C9).withValues(alpha: 0.5),
                  size: 400,
                  alignment: Alignment(-0.8 + 0.3 * math.sin(_controller.value * 2 * math.pi), 
                                      -0.8 + 0.2 * math.cos(_controller.value * 2 * math.pi)),
                ),
                _buildBlob(
                  color: const Color(0xffDCEDC8).withValues(alpha: 0.5),
                  size: 300,
                  alignment: Alignment(0.8 + 0.2 * math.cos(_controller.value * 2 * math.pi), 
                                      -0.5 + 0.4 * math.sin(_controller.value * 2 * math.pi)),
                ),
                _buildBlob(
                  color: const Color(0xFFA5D6A7).withValues(alpha: 0.4),
                  size: 350,
                  alignment: Alignment(0.0 + 0.5 * math.sin(_controller.value * math.pi), 
                                      0.8 + 0.1 * math.cos(_controller.value * 2 * math.pi)),
                ),
              ],
            );
          },
        ),
        // Glass Overlay
        Positioned.fill(
          child: Container(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        // Content
        Positioned.fill(child: widget.child),
      ],
    );
  }

  Widget _buildBlob({
    required Color color,
    required double size,
    required Alignment alignment,
  }) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
