import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'alert_payload.dart';

class RakshakCommunicationService {
  const RakshakCommunicationService();

  Future<bool> openSmsComposer({
    required String phoneNumber,
    required String message,
  }) async {
    final uri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: <String, String>{
        'body': message,
      },
    );

    debugPrint('📱 RAKSHAK: Opening SMS composer');

    if (!await canLaunchUrl(uri)) {
      debugPrint('❌ RAKSHAK: SMS composer unavailable');
      return false;
    }

    return launchUrl(uri);
  }

  Future<bool> openPhoneDialer({
    required String phoneNumber,
  }) async {
    final uri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    debugPrint('📞 RAKSHAK: Opening phone dialer');

    if (!await canLaunchUrl(uri)) {
      debugPrint('❌ RAKSHAK: Phone dialer unavailable');
      return false;
    }

    return launchUrl(uri);
  }

  String buildAlertMessage(RakshakAlertPayload payload) {
  final buffer = StringBuffer()
    ..writeln('🚨 RAKSHAK SOS ALERT')
    ..writeln()
    ..writeln(payload.message)
    ..writeln()
    ..writeln('Time: ${payload.timestamp.toLocal()}');

  final location = payload.location;

  if (location != null) {
    final latitude = location.latitude;
    final longitude = location.longitude;

    buffer
      ..writeln()
      ..writeln('📍 Location: $latitude, $longitude')
      ..writeln(
        'Accuracy: ${location.accuracy?.toStringAsFixed(1) ?? 'unknown'} m',
      )
      ..writeln()
      ..writeln('Map: https://maps.google.com/?q=$latitude,$longitude');
  }

  buffer
    ..writeln()
    ..writeln('Sent using Rakshak.');

  return buffer.toString();
}
}