import '../background/rakshak_safety_event.dart';

enum RakshakSafetyAction {
  testTrigger,
  productionTrigger,
  ignore,
}

class RakshakSafetyPolicy {
  const RakshakSafetyPolicy();

  RakshakSafetyAction evaluate(RakshakSafetyEvent event) {
    switch (event.type) {
      case 'test_safety_event':
        return RakshakSafetyAction.testTrigger;

      case 'sos_trigger':
        return RakshakSafetyAction.productionTrigger;

      default:
        return RakshakSafetyAction.ignore;
    }
  }
}