import 'package:flutter/material.dart';

class ProgressBarWidget extends StatelessWidget {
  final double percentage; // 0.0 to 100.0
  final Color fillColor;

  const ProgressBarWidget({
    Key? key,
    required this.percentage,
    this.fillColor = const Color(0xFF00C49A), // Default green accent
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double clampedPct = percentage.clamp(0.0, 100.0) / 100.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        return Container(
          height: 14,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: const Color(0xFF111111),
              width: 2.0,
            ),
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: maxWidth * clampedPct,
                height: double.infinity,
                color: fillColor,
              ),
            ],
          ),
        );
      },
    );
  }
}
