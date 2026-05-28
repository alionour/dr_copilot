import 'dart:developer';
import 'package:flutter/material.dart';

/// Global variable to track the timestamp of the last executed click.
DateTime? _lastClickTime;

/// Extension on nullable [VoidCallback] to throttle button click events.
extension SafeClickExtension on VoidCallback? {
  /// Wraps the callback to ignore subsequent clicks within the [cooldown] duration.
  /// Defaults to 500 milliseconds, which prevents accidental double taps.
  VoidCallback? throttle([Duration cooldown = const Duration(milliseconds: 500)]) {
    if (this == null) return null;
    return () {
      final now = DateTime.now();
      if (_lastClickTime == null || now.difference(_lastClickTime!) > cooldown) {
        _lastClickTime = now;
        this!();
      } else {
        log('Double click prevented by SafeClickExtension');
      }
    };
  }
}
