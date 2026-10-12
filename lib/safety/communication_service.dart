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
    debugPrint('📱 RAKSHAK: Recipient: $phoneNumber');

    try {
      if (!await canLaunchUrl(uri)) {
        debugPrint('❌ RAKSHAK: SMS composer unavailable');
        return false;
      }

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      debugPrint(
        launched
            ? '✅ RAKSHAK: SMS composer opened'
            : '❌ RAKSHAK: Failed to open SMS composer',
      );

      return launched;
    } catch (e) {
      debugPrint('❌ RAKSHAK: SMS composer error: $e');
      return false;
    }
  }

  Future<bool> openPhoneDialer({
    required String phoneNumber,
  }) async {
    final uri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    debugPrint('📞 RAKSHAK: Opening phone dialer');

    try {
      if (!await canLaunchUrl(uri)) {
        debugPrint('❌ RAKSHAK: Phone dialer unavailable');
        return false;
      }

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      debugPrint(
        launched
            ? '✅ RAKSHAK: Phone dialer opened'
            : '❌ RAKSHAK: Failed to open phone dialer',
      );

      return launched;
    } catch (e) {
      debugPrint('❌ RAKSHAK: Phone dialer error: $e');
      return false;
    }
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
        ..writeln(
          'Map: https://maps.google.com/?q=$latitude,$longitude',
        );
    }

    buffer
      ..writeln()
      ..writeln('Sent using Rakshak.');

    return buffer.toString();
  }
}