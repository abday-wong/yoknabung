import 'package:flutter/material.dart';

class NeoButton extends StatefulWidget {
  final Widget? child;
  final String? text;
  final IconData? icon;
  final Color color;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry padding;
  final double borderWidth;

  const NeoButton({
    Key? key,
    this.child,
    this.text,
    this.icon,
    this.color = const Color(0xFFFFE500), // Default yellow accent
    this.onPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    this.borderWidth = 2.5,
  }) : super(key: key);

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      setState(() {
        _isPressed = true;
      });
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null) {
      setState(() {
        _isPressed = false;
      });
      widget.onPressed!();
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null) {
      setState(() {
        _isPressed = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final shadowOffset = _isPressed ? 1.0 : 3.0;
    final translation = _isPressed ? 2.0 : 0.0;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: Transform.translate(
        offset: Offset(translation, translation),
        child: Container(
          decoration: BoxDecoration(
            color: widget.onPressed == null ? Colors.grey.shade400 : widget.color,
            border: Border.all(
              color: const Color(0xFF111111),
              width: widget.borderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF111111),
                offset: Offset(shadowOffset, shadowOffset),
                blurRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: widget.padding,
            child: widget.child ?? Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: const Color(0xFF111111), size: 20),
                  const SizedBox(width: 8),
                ],
                if (widget.text != null)
                  Text(
                    widget.text!,
                    style: const TextStyle(
                      color: Color(0xFF111111),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
