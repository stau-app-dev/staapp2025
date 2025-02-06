class SpiritMeters {
  final double nine;
  final double ten;
  final double eleven;
  final double twelve;

  const SpiritMeters({
    required this.nine,
    required this.ten,
    required this.eleven,
    required this.twelve,
  });

  factory SpiritMeters.fromJson(Map<String, dynamic> json) {
    return SpiritMeters(
      nine: json['nine'] ?? 0,
      ten: json['ten'] ?? 0,
      eleven: json['eleven'] ?? 0,
      twelve: json['twelve'] ?? 0,
    );
  }

  Map<String, double> toJson() {
    return {
      'nine': nine,
      'ten': ten,
      'eleven': eleven,
      'twelve': twelve,
    };
  }

  SpiritMeters copyWith({
    double? nine,
    double? ten,
    double? eleven,
    double? twelve,
  }) {
    return SpiritMeters(
      nine: nine ?? this.nine,
      ten: ten ?? this.ten,
      eleven: eleven ?? this.eleven,
      twelve: twelve ?? this.twelve,
    );
  }

  @override
  String toString() {
    return 'SpiritMeters(nine: $nine, ten: $ten, eleven: $eleven, twelve: $twelve)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpiritMeters &&
        other.nine == nine &&
        other.ten == ten &&
        other.eleven == eleven &&
        other.twelve == twelve;
  }

  @override
  int get hashCode => Object.hash(nine, ten, eleven, twelve);
}
