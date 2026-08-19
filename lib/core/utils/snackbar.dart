import 'package:flutter/material.dart';

enum SnackBarType { info, success, error, warning }

class AppSnackBar {
  /// Show a snack bar with a simple text message.
  ///
  /// Usage:
  /// ```dart
  /// AppSnackBar.show(context, 'Updating profile...');
  /// AppSnackBar.show(context, 'Saved!', type: SnackBarType.success);
  /// AppSnackBar.show(context, 'Something went wrong', type: SnackBarType.error);
  /// ```
  static void show(
      BuildContext context,
      String message, {
        SnackBarType type = SnackBarType.info,
        Duration duration = const Duration(seconds: 3),
        SnackBarAction? action,
      }) {
    final theme = _resolveTheme(type);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(theme.icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: theme.color,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          action: action,
        ),
      );
  }

  // Convenience constructors
  static void info(BuildContext context, String message,
      {Duration? duration, SnackBarAction? action}) =>
      show(context, message,
          type: SnackBarType.info, duration: duration ?? const Duration(seconds: 3), action: action);

  static void success(BuildContext context, String message,
      {Duration? duration, SnackBarAction? action}) =>
      show(context, message,
          type: SnackBarType.success, duration: duration ?? const Duration(seconds: 3), action: action);

  static void error(BuildContext context, String message,
      {Duration? duration, SnackBarAction? action}) =>
      show(context, message,
          type: SnackBarType.error, duration: duration ?? const Duration(seconds: 4), action: action);

  static void warning(BuildContext context, String message,
      {Duration? duration, SnackBarAction? action}) =>
      show(context, message,
          type: SnackBarType.warning, duration: duration ?? const Duration(seconds: 3), action: action);

  static _SnackBarTheme _resolveTheme(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return _SnackBarTheme(color: const Color(0xFF1565C0), icon: Icons.check_circle_outline);
      case SnackBarType.error:
        return _SnackBarTheme(color: const Color(0xFFC62828), icon: Icons.error_outline);
      case SnackBarType.warning:
        return _SnackBarTheme(color: const Color(0xFFE65100), icon: Icons.warning_amber_rounded);
      case SnackBarType.info:
        return _SnackBarTheme(color: const Color(0xFF4015C0), icon: Icons.info_outline);
    }
  }
}

class _SnackBarTheme {
  final Color color;
  final IconData icon;
  const _SnackBarTheme({required this.color, required this.icon});
}
