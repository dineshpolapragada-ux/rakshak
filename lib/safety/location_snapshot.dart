import 'package:flutter/foundation.dart';

@immutable
class RakshakLocationSnapshot {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime capturedAt;

  const RakshakLocationSnapshot({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.capturedAt,
  });

  @override
  String toString() {
    return 'RakshakLocationSnapshot('
        'latitude: $latitude, '
        'longitude: $longitude, '
        'accuracy: $accuracy, '
        'capturedAt: $capturedAt'
        ')';
  }
}
