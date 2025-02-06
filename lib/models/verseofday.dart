class VerseOfDay {
  final String verseOfDay;

  const VerseOfDay({required this.verseOfDay});

  factory VerseOfDay.fromJson(Map<String, dynamic> json) {
    return VerseOfDay(
      verseOfDay: json['verseOfDay'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'verseOfDay': verseOfDay,
    };
  }
}
