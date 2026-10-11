import 'trusted_contact_action.dart';

class RakshakDispatchResult {
  final bool delivered;
  final String message;
  final DateTime dispatchedAt;

  const RakshakDispatchResult({
    required this.delivered,
    required this.message,
    required this.dispatchedAt,
  });

  @override
  String toString() {
    return 'RakshakDispatchResult('
        'delivered: $delivered, '
        'message: $message, '
        'dispatchedAt: $dispatchedAt'
        ')';
  }
}

abstract class RakshakAlertDispatcher {
  const RakshakAlertDispatcher();

  RakshakDispatchResult dispatch(
    RakshakTrustedContactAction action,
  );
}