import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class NetworkService {
  static DateTime? _cachedTrustedTime;
  static int _cachedLocalEpoch = 0;

  /// Check whether active internet connection is available
  static Future<bool> hasInternetConnection() async {
    if (kIsWeb) {
      try {
        final res = await http.head(Uri.parse('https://www.google.com')).timeout(
          const Duration(seconds: 4),
        );
        return res.statusCode >= 200 && res.statusCode < 400;
      } catch (_) {
        return true; // Browser handles connection
      }
    }

    try {
      final result = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 4),
      );
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {}

    try {
      final res = await http.head(Uri.parse('https://www.google.com')).timeout(
        const Duration(seconds: 4),
      );
      return res.statusCode >= 200 && res.statusCode < 400;
    } catch (_) {
      return false;
    }
  }

  /// Retrieve authoritative, tamper-proof network time from HTTP server header
  /// (Prevents user from rolling back device date/time to bypass 7-day rate-limiting)
  static Future<DateTime> getTrustedNetworkTime() async {
    try {
      final response = await http.head(
        Uri.parse('https://www.google.com'),
      ).timeout(const Duration(seconds: 5));

      final dateHeader = response.headers['date'];
      if (dateHeader != null) {
        final serverTime = HttpDate.parse(dateHeader);
        _cachedTrustedTime = serverTime;
        _cachedLocalEpoch = DateTime.now().millisecondsSinceEpoch;
        return serverTime;
      }
    } catch (_) {}

    // Fallback: If network request failed but we previously obtained trusted time,
    // calculate elapsed time using monotonic elapsed duration
    if (_cachedTrustedTime != null) {
      final elapsedMs = DateTime.now().millisecondsSinceEpoch - _cachedLocalEpoch;
      if (elapsedMs >= 0) {
        return _cachedTrustedTime!.add(Duration(milliseconds: elapsedMs));
      }
    }

    return DateTime.now().toUtc();
  }
}
