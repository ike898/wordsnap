import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/word_provider.dart';
import '../widgets/banner_ad_widget.dart';

class WordsScreen extends ConsumerWidget {
  const WordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordsAsync = ref.watch(wordsProvider);
    final mastered = ref.watch(masteredCountProvider);
    final todayLearned = ref.watch(todayLearnedProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: wordsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (words) {
              if (words.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.translate, size: 64,
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text('No words yet', style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 8),
                      Text('Use the camera to discover words',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Stats row
                  Row(
                    children: [
                      _MiniStat(
                          label: 'Total', value: '${words.length}',
                          theme: theme),
                      const SizedBox(width: 8),
                      _MiniStat(
                          label: 'Mastered', value: '$mastered',
                          theme: theme),
                      const SizedBox(width: 8),
                      _MiniStat(
                          label: 'Today', value: '$todayLearned',
                          theme: theme),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Word List', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...words.reversed.map((word) => Dismissible(
                        key: Key(word.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          color: Colors.red,
                          child: const Icon(Icons.delete,
                              color: Colors.white),
                        ),
                        onDismissed: (_) {
                          ref
                              .read(wordsProvider.notifier)
                              .deleteWord(word.id);
                        },
                        child: Card(
                          child: ListTile(
                            title: Text(word.englishWord,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(word.translatedWord),
                            trailing: word.mastered
                                ? Icon(Icons.check_circle,
                                    color: Colors.green)
                                : IconButton(
                                    icon: const Icon(
                                        Icons.check_circle_outline),
                                    onPressed: () {
                                      ref
                                          .read(wordsProvider.notifier)
                                          .markMastered(word.id);
                                    },
                                  ),
                          ),
                        ),
                      )),
                ],
              );
            },
          ),
        ),
        const BannerAdWidget(),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _MiniStat(
      {required this.label, required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(value,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(label,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}
