class Alert {
  final DateTime ts;
  final String source;
  final String text;

  Alert({required this.ts, required this.source, required this.text});

  factory Alert.fromJson(Map<String, dynamic> json) {
    final rawTs = json['ts'];
    final seconds = (rawTs is num) ? rawTs.toDouble() : 0.0;
    return Alert(
      ts: DateTime.fromMillisecondsSinceEpoch((seconds * 1000).round(), isUtc: true).toLocal(),
      source: (json['source'] as String?) ?? 'general',
      text: (json['text'] as String?) ?? '',
    );
  }
}
