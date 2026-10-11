import 'package:flutter/foundation.dart';

@immutable
class RakshakAlertRecipient {
  final String contactId;
  final String displayName;
  final String phoneNumber;

  const RakshakAlertRecipient({
    required this.contactId,
    required this.displayName,
    required this.phoneNumber,
  });

  @override
  String toString() {
    return 'RakshakAlertRecipient('
        'contactId: $contactId, '
        'displayName: $displayName, '
        'phoneNumber: $phoneNumber'
        ')';
  }
}
