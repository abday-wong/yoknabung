import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/savings_provider.dart';

class ProgressBarWidget extends StatelessWidget {
  final double percentage;
  final Color fillColor;

  const ProgressBarWidget({
    super.key,
    required this.percentage,
    this.fillColor = const Color(0xFF00C49A),
  });

  @override
  Widget build(BuildContext context) {
    final double clampedPct = percentage.clamp(0.0, 100.0) / 100.0;
    
    bool isDark = false;
    try {
      isDark = Provider.of<SavingsProvider>(context).isDarkMode;
    } catch (_) {
    }
    
    final borderColor = isDark ? Colors.white : const Color(0xFF111111);
    final emptyBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        return Container(
          height: 14,
          decoration: BoxDecoration(
            color: emptyBgColor,
            border: Border.all(
              color: borderColor,
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
