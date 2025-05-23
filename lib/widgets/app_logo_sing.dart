import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;

/// Animated singing JazzX logo widget
class AppLogoSing extends StatefulWidget {
  final double size;
  final Duration duration;
  const AppLogoSing({
    super.key,
    this.size = 120,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<AppLogoSing> createState() => _AppLogoSingState();
}

class _AppLogoSingState extends State<AppLogoSing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _mouthOpenAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
    _mouthOpenAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.asset(
            'assets/jazzx_logo.svg',
            width: widget.size,
            height: widget.size,
          ),
          AnimatedBuilder(
            animation: _mouthOpenAnim,
            builder: (context, child) {
              // This assumes the logo has a mouth at a certain position. Adjust as needed.
              return Positioned(
                bottom: widget.size * 0.22,
                left: widget.size * 0.37,
                child: CustomPaint(
                  painter: _MouthPainter(_mouthOpenAnim.value, widget.size),
                  size: Size(widget.size * 0.26, widget.size * 0.12),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MouthPainter extends CustomPainter {
  final double open;
  final double size;
  _MouthPainter(this.open, this.size);

  @override
  void paint(Canvas canvas, Size sz) {
    final paint =
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.fill;
    // Draw an animated mouth (ellipse opening)
    final mouthWidth = sz.width;
    final mouthHeight = sz.height * (0.3 + 0.7 * open);
    final mouthRect = Rect.fromCenter(
      center: Offset(mouthWidth / 2, sz.height / 2),
      width: mouthWidth,
      height: mouthHeight,
    );
    canvas.drawOval(mouthRect, paint);
  }

  @override
  bool shouldRepaint(_MouthPainter oldDelegate) => oldDelegate.open != open;
}
