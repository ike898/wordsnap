import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../models/word_entry.dart';

final targetLanguageProvider = StateProvider<String>((ref) => 'ja');

final wordsProvider =
    AsyncNotifierProvider<WordsNotifier, List<WordEntry>>(WordsNotifier.new);

final masteredCountProvider = Provider<int>((ref) {
  final words = ref.watch(wordsProvider).valueOrNull ?? [];
  return words.where((w) => w.mastered).length;
});

final todayLearnedProvider = Provider<int>((ref) {
  final words = ref.watch(wordsProvider).valueOrNull ?? [];
  final today = DateTime.now();
  return words
      .where((w) =>
          w.learnedAt.year == today.year &&
          w.learnedAt.month == today.month &&
          w.learnedAt.day == today.day)
      .length;
});

class WordsNotifier extends AsyncNotifier<List<WordEntry>> {
  @override
  Future<List<WordEntry>> build() async => _load();

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/words.json');
  }

  Future<List<WordEntry>> _load() async {
    try {
      final file = await _file;
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString()) as List;
        return json
            .map((e) => WordEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> _save(List<WordEntry> words) async {
    final file = await _file;
    await file
        .writeAsString(jsonEncode(words.map((w) => w.toJson()).toList()));
  }

  Future<void> addWord(WordEntry word) async {
    final current = state.valueOrNull ?? [];
    // Skip duplicates
    if (current.any((w) =>
        w.englishWord == word.englishWord &&
        w.targetLanguage == word.targetLanguage)) {
      return;
    }
    final updated = [...current, word];
    state = AsyncData(updated);
    await _save(updated);
  }

  Future<void> markMastered(String id) async {
    final current = (state.valueOrNull ?? []).map((w) {
      if (w.id != id) return w;
      return w.copyWith(mastered: true, reviewCount: w.reviewCount + 1);
    }).toList();
    state = AsyncData(current);
    await _save(current);
  }

  Future<void> deleteWord(String id) async {
    final current =
        (state.valueOrNull ?? []).where((w) => w.id != id).toList();
    state = AsyncData(current);
    await _save(current);
  }
}
