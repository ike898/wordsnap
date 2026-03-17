import 'dart:convert';
import 'package:flutter/services.dart';

class DictionaryService {
  static Map<String, Map<String, String>>? _dictionary;

  static Future<void> load() async {
    if (_dictionary != null) return;
    final jsonStr = await rootBundle.loadString('assets/dictionary.json');
    final raw = jsonDecode(jsonStr) as Map<String, dynamic>;
    _dictionary = raw.map((key, value) => MapEntry(
        key,
        (value as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v as String))));
  }

  static String? translate(String englishWord, String targetLang) {
    if (_dictionary == null) return null;
    final lower = englishWord.toLowerCase().trim();
    return _dictionary![lower]?[targetLang];
  }

  static Map<String, String>? getTranslations(String englishWord) {
    if (_dictionary == null) return null;
    return _dictionary![englishWord.toLowerCase().trim()];
  }

  static int get wordCount => _dictionary?.length ?? 0;
}
