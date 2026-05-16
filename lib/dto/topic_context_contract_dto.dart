class LatestNodeDto {
  const LatestNodeDto({
    required this.id,
    required this.occurredAt,
    required this.headline,
    required this.summary,
    required this.isMajor,
    this.primarySignal,
    this.signals = const <String>[],
    this.signalConfidence,
  });

  final String id;
  final DateTime occurredAt;
  final String headline;
  final String summary;
  final bool isMajor;
  final String? primarySignal;
  final List<String> signals;
  final double? signalConfidence;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'occurredAt': occurredAt.toIso8601String(),
      'headline': headline,
      'summary': summary,
      'isMajor': isMajor,
      if (primarySignal != null) 'primarySignal': primarySignal,
      if (signals.isNotEmpty) 'signals': signals,
      if (signalConfidence != null) 'signalConfidence': signalConfidence,
    };
  }

  factory LatestNodeDto.fromJson(Map<String, dynamic> json) {
    return LatestNodeDto(
      id: json['id'] as String? ?? '',
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      headline: json['headline'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      isMajor: json['isMajor'] as bool? ?? false,
      primarySignal: json['primarySignal'] as String?,
      signals: readStringList(json['signals']),
      signalConfidence: readDouble(json['signalConfidence']),
    );
  }
}

List<String> readStringList(dynamic value) {
  return (value as List<dynamic>? ?? const <dynamic>[])
      .whereType<String>()
      .toList(growable: false);
}

double? readDouble(dynamic value) => (value as num?)?.toDouble();

DateTime? readDateTime(dynamic value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return DateTime.parse(value);
}
