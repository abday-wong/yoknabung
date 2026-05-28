import 'package:flutter/material.dart';
import 'neo_button.dart';

class NeoDialog {
  static Future<T?> showNeoDialog<T>({
    required BuildContext context,
    required String title,
    required String body,
    required String primaryLabel,
    required VoidCallback onPrimaryPressed,
    String? secondaryLabel,
    VoidCallback? onSecondaryPressed,
    Color primaryColor = const Color(0xFFFFE500),
  }) {
    return showDialog<T>(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDE7), // cream
              border: Border.all(color: const Color(0xFF111111), width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF111111),
                  offset: Offset(5, 5),
                  blurRadius: 0,
                ),
              ],
            ),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (secondaryLabel != null) ...[
                      NeoButton(
                        text: secondaryLabel,
                        color: Colors.white,
                        onPressed: onSecondaryPressed ?? () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                    ],
                    NeoButton(
                      text: primaryLabel,
                      color: primaryColor,
                      onPressed: onPrimaryPressed,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void showNeoSnackbar(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF111111),
        behavior: SnackBarBehavior.floating,
        shape: Border.all(color: const Color(0xFF111111), width: 2),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 0,
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: const Color(0xFFFFE500),
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  static Future<T?> showNeoBottomSheet<T>({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: const Color(0xFFFFFDE7),
      elevation: 0,
      shape: const Border(
        top: BorderSide(color: Color(0xFF111111), width: 2.5),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    color: const Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 20),
                ...children,
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
