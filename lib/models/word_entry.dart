class WordEntry {
  final String id;
  final String englishWord;
  final String translatedWord;
  final String targetLanguage;
  final double confidence;
  final DateTime learnedAt;
  final int reviewCount;
  final bool mastered;

  WordEntry({
    required this.id,
    required this.englishWord,
    required this.translatedWord,
    required this.targetLanguage,
    required this.confidence,
    required this.learnedAt,
    this.reviewCount = 0,
    this.mastered = false,
  });

  WordEntry copyWith({
    int? reviewCount,
    bool? mastered,
  }) {
    return WordEntry(
      id: id,
      englishWord: englishWord,
      translatedWord: translatedWord,
      targetLanguage: targetLanguage,
      confidence: confidence,
      learnedAt: learnedAt,
      reviewCount: reviewCount ?? this.reviewCount,
      mastered: mastered ?? this.mastered,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'englishWord': englishWord,
        'translatedWord': translatedWord,
        'targetLanguage': targetLanguage,
        'confidence': confidence,
        'learnedAt': learnedAt.toIso8601String(),
        'reviewCount': reviewCount,
        'mastered': mastered,
      };

  factory WordEntry.fromJson(Map<String, dynamic> json) => WordEntry(
        id: json['id'] as String,
        englishWord: json['englishWord'] as String,
        translatedWord: json['translatedWord'] as String,
        targetLanguage: json['targetLanguage'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        learnedAt: DateTime.parse(json['learnedAt'] as String),
        reviewCount: json['reviewCount'] as int? ?? 0,
        mastered: json['mastered'] as bool? ?? false,
      );
}
