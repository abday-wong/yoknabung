import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/savings_provider.dart';

class NeoCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderWidth;
  final double shadowOffset;

  const NeoCard({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.borderWidth = 2.5,
    this.shadowOffset = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<SavingsProvider>(context).isDarkMode;
    final borderColor = isDark ? Colors.white : const Color(0xff111111);
    final shadowColor = isDark ? Colors.black : const Color(0xff111111);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            offset: Offset(shadowOffset, shadowOffset),
            blurRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: child,
      ),
    );
  }
}
