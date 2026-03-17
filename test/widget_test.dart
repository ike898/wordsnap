import 'package:flutter_test/flutter_test.dart';
import 'package:wordsnap/models/word_entry.dart';

void main() {
  test('WordEntry JSON round-trip', () {
    final entry = WordEntry(
      id: '1',
      englishWord: 'dog',
      translatedWord: '犬',
      targetLanguage: 'ja',
      confidence: 0.95,
      learnedAt: DateTime(2024, 1, 1),
    );
    final json = entry.toJson();
    final restored = WordEntry.fromJson(json);
    expect(restored.id, '1');
    expect(restored.englishWord, 'dog');
    expect(restored.translatedWord, '犬');
    expect(restored.targetLanguage, 'ja');
    expect(restored.confidence, 0.95);
    expect(restored.mastered, false);
  });

  test('WordEntry copyWith mastered', () {
    final entry = WordEntry(
      id: '1',
      englishWord: 'cat',
      translatedWord: '猫',
      targetLanguage: 'ja',
      confidence: 0.8,
      learnedAt: DateTime.now(),
    );
    final mastered = entry.copyWith(mastered: true, reviewCount: 3);
    expect(mastered.mastered, true);
    expect(mastered.reviewCount, 3);
    expect(mastered.englishWord, 'cat');
  });
}
