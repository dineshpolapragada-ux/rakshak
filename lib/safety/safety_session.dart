import 'package:flutter/foundation.dart';

import 'safety_state.dart';

@immutable
class RakshakSafetySession {
  final String sessionId;
  final DateTime startedAt;
  final String triggerType;
  final String triggerSource;
  final RakshakSafetyState state;

  const RakshakSafetySession({
    required this.sessionId,
    required this.startedAt,
    required this.triggerType,
    required this.triggerSource,
    required this.state,
  });

  RakshakSafetySession copyWith({
    String? sessionId,
    DateTime? startedAt,
    String? triggerType,
    String? triggerSource,
    RakshakSafetyState? state,
  }) {
    return RakshakSafetySession(
      sessionId: sessionId ?? this.sessionId,
      startedAt: startedAt ?? this.startedAt,
      triggerType: triggerType ?? this.triggerType,
      triggerSource: triggerSource ?? this.triggerSource,
      state: state ?? this.state,
    );
  }

  @override
  String toString() {
    return 'RakshakSafetySession('
        'sessionId: $sessionId, '
        'startedAt: $startedAt, '
        'triggerType: $triggerType, '
        'triggerSource: $triggerSource, '
        'state: $state'
        ')';
  }
}
