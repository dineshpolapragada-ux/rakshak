import '../safety/safety_state.dart';

class RakshakIncident {
  final String id;
  final DateTime createdAt;
  final String triggerType;
  final String triggerSource;
  final RakshakSafetyState state;
  final DateTime lastUpdatedAt;

  const RakshakIncident({
    required this.id,
    required this.createdAt,
    required this.triggerType,
    required this.triggerSource,
    required this.state,
    required this.lastUpdatedAt,
  });

  RakshakIncident copyWith({
    String? id,
    DateTime? createdAt,
    String? triggerType,
    String? triggerSource,
    RakshakSafetyState? state,
    DateTime? lastUpdatedAt,
  }) {
    return RakshakIncident(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      triggerType: triggerType ?? this.triggerType,
      triggerSource: triggerSource ?? this.triggerSource,
      state: state ?? this.state,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  @override
  String toString() {
    return 'RakshakIncident('
        'id: $id, '
        'createdAt: $createdAt, '
        'triggerType: $triggerType, '
        'triggerSource: $triggerSource, '
        'state: $state, '
        'lastUpdatedAt: $lastUpdatedAt'
        ')';
  }
}