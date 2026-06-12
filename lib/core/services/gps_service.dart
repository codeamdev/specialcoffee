import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class GpsResult {
  const GpsResult({
    required this.latitude,
    required this.longitude,
    required this.altitudeMeters,
  });
  final double latitude;
  final double longitude;
  final double altitudeMeters;
}

class GpsPermissionDeniedException implements Exception {
  const GpsPermissionDeniedException();
}

class GpsUnavailableException implements Exception {
  const GpsUnavailableException();
}

class GpsService {
  bool get _supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Solicita permisos y devuelve posición actual.
  /// No-op en Windows — retorna null sin lanzar excepción.
  Future<GpsResult?> getCurrentPosition() async {
    if (!_supported) return null;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw const GpsUnavailableException();

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const GpsPermissionDeniedException();
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 15),
      ),
    );

    return GpsResult(
      latitude:       pos.latitude,
      longitude:      pos.longitude,
      altitudeMeters: pos.altitude,
    );
  }
}
