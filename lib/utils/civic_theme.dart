import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CivicTheme {
  // Vibrant Municipal Orange / Saffron Brand Tokens
  static const Color primary = Color(0xFFE65100);      // Nagpur Municipal Saffron/Orange
  static const Color primaryDark = Color(0xFFC43E00);  // Deep Municipal Orange
  static const Color accent = Color(0xFFFF6B00);       // Radiant Orange Accent
  static const Color background = Color(0xFFF8F9FA);   // Warm Off-White
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A1C1C);  // Deep Charcoal
  static const Color textSecondary = Color(0xFF64748B);// Muted Slate
  static const Color border = Color(0xFFE2E8F0);

  // Status Colors
  static const Color statusOpen = Color(0xFFDC2626);      // Crimson Red
  static const Color statusInProgress = Color(0xFFE65100);// Orange
  static const Color statusResolved = Color(0xFF16A34A);  // Emerald Green

  // Official Orange Gradient
  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFE65100), Color(0xFFFF6B00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Universal Photo Rendering Widget
/// Seamlessly renders local gallery/camera file paths AND remote Supabase HTTP URLs
/// with automatic fallback so images are NEVER lost or broken!
Widget buildCivicPhoto(
  String? url, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  BorderRadius? borderRadius,
}) {
  Widget placeholder = Container(
    width: width,
    height: height,
    color: const Color(0xFFFFF0E5),
    child: const Center(
      child: Icon(
        Icons.image_outlined,
        color: Color(0xFFE65100),
        size: 28,
      ),
    ),
  );

  if (url == null || url.trim().isEmpty) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: placeholder,
    );
  }

  final cleanUrl = url.trim();

  Widget imageWidget;

  // 1. Remote HTTP / Supabase URL
  if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
    imageWidget = Image.network(
      cleanUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => placeholder,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          width: width,
          height: height,
          color: const Color(0xFFFFF0E5),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: CivicTheme.primary,
              ),
            ),
          ),
        );
      },
    );
  }
  // 2. Local File System Image (Gallery / Camera on Device)
  else if (!kIsWeb) {
    try {
      final file = File(cleanUrl);
      if (file.existsSync()) {
        imageWidget = Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => placeholder,
        );
      } else {
        imageWidget = placeholder;
      }
    } catch (_) {
      imageWidget = placeholder;
    }
  } else {
    imageWidget = placeholder;
  }

  if (borderRadius != null) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: imageWidget,
    );
  }

  return imageWidget;
}
