class RakshakSafetyEvent {
  final String type;
  final String message;
  final DateTime timestamp;
  final String source;

  const RakshakSafetyEvent({
    required this.type,
    required this.message,
    required this.timestamp,
    required this.source,
  });

  factory RakshakSafetyEvent.fromMap(Map data) {
    return RakshakSafetyEvent(
      type: data['type']?.toString() ?? 'unknown',
      message: data['message']?.toString() ?? '',
      timestamp: DateTime.tryParse(
            data['time']?.toString() ?? '',
          ) ??
          DateTime.now(),
      source: data['source']?.toString() ?? 'unknown',
    );
  }

  @override
  String toString() {
    return 'RakshakSafetyEvent('
        'type: $type, '
        'message: $message, '
        'timestamp: $timestamp, '
        'source: $source'
        ')';
  }
}
