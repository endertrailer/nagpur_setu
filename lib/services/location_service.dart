import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Check if Location Services and Permissions are enabled
  static Future<bool> isLocationReady() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  /// Request Location Permission from the user
  static Future<Map<String, dynamic>> requestLocationPermission(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return {
        'granted': false,
        'message': 'Please turn ON your device GPS / Location Services to use Nagpur Setu.',
      };
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return {
          'granted': false,
          'message': 'Location permission was denied. Live GPS is mandatory to verify issues in Nagpur.',
        };
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return {
        'granted': false,
        'message': 'Location permission is permanently denied. Please enable it in App Settings.',
      };
    }

    return {
      'granted': true,
      'message': 'Location permission granted successfully.',
    };
  }

  /// Retrieve current device GPS coordinates
  static Future<Position?> getCurrentDeviceLocation(BuildContext context) async {
    final status = await requestLocationPermission(context);
    if (!status['granted']) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status['message']),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return position;
    } catch (e) {
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        return lastKnown;
      } catch (_) {
        return null;
      }
    }
  }
}
