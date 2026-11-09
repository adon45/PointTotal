class MediaEntry {
  MediaEntry({
    required this.id,
    required this.label,
    required this.points,
    required this.timestamp,
    this.sqftRange,
    this.acres,
  });

  factory MediaEntry.create({
    required String label,
    required double points,
    required DateTime timestamp,
    String? sqftRange,
    String? acres,
  }) {
    return MediaEntry(
      id: '${timestamp.microsecondsSinceEpoch}-${_nextId++}',
      label: label,
      points: points,
      timestamp: timestamp,
      sqftRange: sqftRange,
      acres: acres,
    );
  }

  factory MediaEntry.fromJson(Map<String, dynamic> json) {
    return MediaEntry(
      id: json['id'] as String,
      label: json['label'] as String,
      sqftRange: json['sqftRange'] as String?,
      acres: json['acres'] as String?,
      points: (json['points'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String).toLocal(),
    );
  }

  static int _nextId = 0;

  final String id;
  final String label;
  final String? sqftRange;
  final String? acres;
  final double points;
  final DateTime timestamp;

  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'sqftRange': sqftRange,
    'acres': acres,
    'points': points,
    'timestamp': timestamp.toIso8601String(),
  };
}
