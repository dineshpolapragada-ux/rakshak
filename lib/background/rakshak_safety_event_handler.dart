import 'package:flutter/foundation.dart';

import 'rakshak_safety_event.dart';
import '../safety/safety_controller.dart';

class RakshakSafetyEventHandler {
  static final RakshakSafetyController _controller =
      RakshakSafetyController();
  static RakshakSafetyController get controller => _controller;

  static void handle(RakshakSafetyEvent event) {
    debugPrint(
      '🛡️ RAKSHAK SAFETY EVENT HANDLER: '
      '${event.type} | '
      '${event.message} | '
      'source=${event.source}',
    );

    _controller.handleEvent(event);

    debugPrint(
      '🧠 RAKSHAK SAFETY STATE: '
      '${_controller.state}',
    );
  }
}
