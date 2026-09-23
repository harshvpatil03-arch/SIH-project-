// lib/core/services/gps_service.dart
import 'dart:async';
import 'package:geolocator/geolocator.dart';

class GpsResult {
  final double latitude;
  final double longitude;
  final String accuracyMode; // 'SATELLITE_HIGH_ACCURACY' or 'NETWORK_COARSE_FALLBACK'
  final DateTime timestamp;
  final String? warningMessage;

  GpsResult({
    required this.latitude,
    required this.longitude,
    required this.accuracyMode,
    required this.timestamp,
    this.warningMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy_mode': accuracyMode,
      'timestamp': timestamp.toIso8601String(),
      'warning_message': warningMessage,
    };
  }
}

class GpsService {
  static final GpsService _instance = GpsService._internal();
  factory GpsService() => _instance;
  GpsService._internal();

  /// Captures actual device coordinates via Geolocator.
  /// Checks service availability and requests permissions dynamically.
  Future<GpsResult> captureLocation() async {
    try {
      // 1. Check if GPS location service is enabled on the device
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        return await _acquireCoarseFallback(
          'Location services are turned off. Please turn on GPS in device settings.',
        );
      }

      // 2. Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return await _acquireCoarseFallback(
            'Location permission was denied. Tap to grant location access.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return await _acquireCoarseFallback(
          'Location permissions permanently denied. Enable in App Settings.',
        );
      }

      // 3. Acquire actual high-accuracy position with 8-second timeout
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      return GpsResult(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMode: 'SATELLITE_HIGH_ACCURACY',
        timestamp: position.timestamp.toUtc(),
        warningMessage: null,
      );
    } catch (e) {
      // Fallback to last known location if satellite fix is delayed
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          return GpsResult(
            latitude: lastKnown.latitude,
            longitude: lastKnown.longitude,
            accuracyMode: 'NETWORK_COARSE_FALLBACK',
            timestamp: lastKnown.timestamp.toUtc(),
            warningMessage: 'GPS lock timeout. Applied last known device location.',
          );
        }
      } catch (_) {}

      return await _acquireCoarseFallback('GPS error: $e');
    }
  }

  Future<GpsResult> _acquireCoarseFallback([String? reason]) async {
    // Jurisdiction fallback (Delhi NCR Circle 04)
    return GpsResult(
      latitude: 28.535516,
      longitude: 77.391026,
      accuracyMode: 'NETWORK_COARSE_FALLBACK',
      timestamp: DateTime.now().toUtc(),
      warningMessage: reason ?? 'Satellite lock unavailable. Coarse fallback applied.',
    );
  }
}
