import 'dart:ui';
import 'package:flutter/material.dart';

// A shared extension to create frosted glass and glowing orb effects
extension BlurExtension on Widget {
  Widget applyBlur({double sigma = 10.0}) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: this,
    );
  }
}