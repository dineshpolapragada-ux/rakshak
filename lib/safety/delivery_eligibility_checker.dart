import 'delivery_eligibility.dart';
import 'alert_payload.dart';

class RakshakDeliveryEligibilityChecker {
  const RakshakDeliveryEligibilityChecker();

  RakshakDeliveryEligibility check(
    RakshakAlertPayload payload,
  ) {
    if (payload.trustedContactIds.isEmpty) {
      return const RakshakDeliveryEligibility(
        eligible: false,
        reason: 'No trusted contacts are configured.',
      );
    }

    if (payload.message.trim().isEmpty) {
      return const RakshakDeliveryEligibility(
        eligible: false,
        reason: 'Alert message is empty.',
      );
    }

    if (payload.recipients.isEmpty) {
      return const RakshakDeliveryEligibility(
        eligible: false,
        reason: 'No alert recipients are configured.',
      );
    }

    for (final recipient in payload.recipients) {
      if (recipient.contactId.trim().isEmpty) {
        return const RakshakDeliveryEligibility(
          eligible: false,
          reason: 'An alert recipient is missing a contact ID.',
        );
      }

      if (recipient.phoneNumber.trim().isEmpty) {
        return const RakshakDeliveryEligibility(
          eligible: false,
          reason: 'An alert recipient is missing a phone number.',
        );
      }
    }

    if (payload.testMode) {
      return const RakshakDeliveryEligibility(
        eligible: false,
        reason: 'Test-mode payload cannot enter production delivery.',
      );
    }

    return const RakshakDeliveryEligibility(
      eligible: true,
      reason: 'Alert payload passed delivery eligibility checks.',
    );
  }
}

