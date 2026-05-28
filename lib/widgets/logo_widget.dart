import 'dart:math';
import 'package:flutter/material.dart';

class LogoWidget extends StatelessWidget {
  final double size;
  final bool hasBorder;

  const LogoWidget({
    Key? key,
    this.size = 40.0,
    this.hasBorder = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: hasBorder
          ? BoxDecoration(
              border: Border.all(color: const Color(0xFF111111), width: 2.5),
            )
          : null,
      child: CustomPaint(
        size: Size(size, size),
        painter: _LogoPainter(),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2;

    final Paint redPaint = Paint()
      ..color = const Color(0xFFFF0000) // Vibrant Red
      ..style = PaintingStyle.fill;

    final Paint blackPaint = Paint()
      ..color = const Color(0xFF111111) // Bold Black
      ..style = PaintingStyle.fill;

    final Paint strokePaint = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.04
      ..strokeCap = StrokeCap.round;

    // 1. Draw Red Background Square
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), redPaint);

    // 2. Draw Radiating Black Rays (Wedges)
    final int rayCount = 18;
    final double angleStep = (2 * pi) / rayCount;
    final double innerR = r * 0.15;
    final double outerR = r * 1.5;

    for (int i = 0; i < rayCount; i++) {
      final double baseAngle = i * angleStep;
      final double nextAngle = baseAngle + (angleStep * 0.45); // width of the wedge

      final Path rayPath = Path()
        ..moveTo(cx + innerR * cos(baseAngle), cy + innerR * sin(baseAngle))
        ..lineTo(cx + outerR * cos(baseAngle), cy + outerR * sin(baseAngle))
        ..lineTo(cx + outerR * cos(nextAngle), cy + outerR * sin(nextAngle))
        ..lineTo(cx + innerR * cos(nextAngle), cy + innerR * sin(nextAngle))
        ..close();

      canvas.drawPath(rayPath, blackPaint);
    }

    // 3. Draw Eyelashes / Bottom Spikes
    // We want to draw 5 spikes pointing downwards from the bottom eyelid area.
    final Path spikesPath = Path();
    final double eyeW = size.width * 0.65;
    final double eyeH = size.height * 0.28;

    // Generate spikes
    final int spikeCount = 5;
    for (int i = 0; i < spikeCount; i++) {
      // Interpolate along the eye bottom width
      final double t = (i + 1) / (spikeCount + 1); // 0.16 to 0.83
      final double xOffset = (t - 0.5) * eyeW;
      
      // Y position along the bottom curve (parabolic approximation)
      final double yOffset = (4 * eyeH * t * (1 - t)) * 0.6; 
      
      final double startX = cx + xOffset;
      final double startY = cy + yOffset;

      // Draw triangle pointing downwards
      final double spikeW = size.width * 0.06;
      final double spikeH = size.height * 0.12;

      final Path spike = Path()
        ..moveTo(startX - spikeW / 2, startY)
        ..lineTo(startX, startY + spikeH)
        ..lineTo(startX + spikeW / 2, startY)
        ..close();
      canvas.drawPath(spike, blackPaint);
    }

    // 4. Draw Eyelids Outline
    // Top Eyelid
    final Path eyeOutline = Path()
      ..moveTo(cx - eyeW / 2, cy)
      ..quadraticBezierTo(cx, cy - eyeH, cx + eyeW / 2, cy)
      ..quadraticBezierTo(cx, cy + eyeH, cx - eyeW / 2, cy)
      ..close();

    // Fill eye background with red (covering the rays inside the eye)
    canvas.drawPath(eyeOutline, redPaint);
    // Draw bold black stroke around the eye
    canvas.drawPath(eyeOutline, strokePaint);

    // 5. Draw Iris (Central Circle)
    final double irisR = size.width * 0.18;
    canvas.drawCircle(Offset(cx, cy), irisR, blackPaint);
    canvas.drawCircle(Offset(cx, cy), irisR * 0.75, redPaint);

    // 6. Draw Black Star in the Center
    final double starR = irisR * 0.55;
    final Path starPath = Path();
    final int starPoints = 5;

    for (int i = 0; i < starPoints * 2; i++) {
      final double angle = -pi / 2 + i * pi / starPoints;
      final double currentR = (i % 2 == 0) ? starR : (starR * 0.45);
      final double x = cx + currentR * cos(angle);
      final double y = cy + currentR * sin(angle);

      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
    }
    starPath.close();
    canvas.drawPath(starPath, blackPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
