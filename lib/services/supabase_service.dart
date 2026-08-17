import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://zgbqawweziyegdsripvy.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_2Jwqwtge8xEjFy4c8cD81Q_ozk3_Jo2';

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // ignore: deprecated_member_use
      await Supabase.initialize(
        url: supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: supabaseAnonKey,
        realtimeClientOptions: const RealtimeClientOptions(
          eventsPerSecond: 10,
        ),
      );
      _initialized = true;
    } catch (e) {
      // Fallback to offline / mock mode if network not ready during boot
      _initialized = false;
    }
  }

  static SupabaseClient? get client {
    if (!_initialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }
}
