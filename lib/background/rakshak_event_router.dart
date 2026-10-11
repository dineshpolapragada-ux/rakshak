import 'package:flutter/foundation.dart';

import 'rakshak_safety_event.dart';
import 'rakshak_safety_event_handler.dart';

class RakshakEventRouter {
  static void handle(Object data) {
    debugPrint('🧭 RAKSHAK EVENT ROUTER: $data');

    if (data is RakshakSafetyEvent) {
      RakshakSafetyEventHandler.handle(data);
      return;
    }

    if (data is! Map) {
      debugPrint('⚠️ Unknown Rakshak event format');
      return;
    }

    final type = data['type'];

    switch (type) {
  case 'heartbeat':
    _handleHeartbeat(data);
    break;

  case 'test_safety_event':
    _handleTestSafetyEvent(data);
    break;

  case 'sos_trigger':
    _handleSosTrigger(data);
    break;

  default:
    debugPrint('⚠️ Unknown Rakshak event type: $type');
}
  }

  static void _handleHeartbeat(Map data) {
    debugPrint('💓 Rakshak heartbeat received: ${data['time']}');
  }

  static void _handleTestSafetyEvent(Map data) {
    final event = RakshakSafetyEvent.fromMap(data);

    debugPrint('🚨 Rakshak safety event received:');

    debugPrint(event.toString());

    RakshakSafetyEventHandler.handle(event);
  }
  static void _handleSosTrigger(Map data) {
  debugPrint('🚨 RAKSHAK BACKGROUND SOS EVENT RECEIVED');
  debugPrint(
    '🎙️ Background voice SOS request received by event router',
  );
}
}
