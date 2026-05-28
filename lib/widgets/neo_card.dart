import 'package:flutter/material.dart';

class NeoCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderWidth;
  final double shadowOffset;

  const NeoCard({
    Key? key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.borderWidth = 2.5,
    this.shadowOffset = 4.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(
          color: const Color(0xff111111),
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff111111),
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
