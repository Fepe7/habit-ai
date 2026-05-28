import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/ux/app_snackbar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/mood_repository.dart';
import '../../domain/mood_entry_model.dart';

// Bottom sheet con los registros de ánimo de un día concreto
class MoodDayDetailSheet extends StatelessWidget {
  final DateTime date;
  final List<MoodEntryModel> entries;
  final VoidCallback? onDeleted;

  const MoodDayDetailSheet({
    super.key,
    required this.date,
    required this.entries,
    this.onDeleted,
  });

  static Future<void> show(
    BuildContext context, {
    required DateTime date,
    required List<MoodEntryModel> entries,
    VoidCallback? onDeleted,
  }) {
    return showAppBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      builder: (_) => MoodDayDetailSheet(
        date: date,
        entries: entries,
        onDeleted: onDeleted,
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime d) {
    final s = S.of(context);
    final months = [
      s.monthJan, s.monthFeb, s.monthMar, s.monthApr, s.monthMay, s.monthJun,
      s.monthJul, s.monthAug, s.monthSep, s.monthOct, s.monthNov, s.monthDec,
    ];
    return '${d.day} ${months[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24, 24, 24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _formatDate(context, date),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                s.moodNoEntriesDay,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, i) => _EntryTile(
                entry: entries[i],
                onDelete: () async {
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid == null) return;
                  try {
                    await MoodRepository(uid: uid).deleteEntry(entries[i].id);
                    onDeleted?.call();
                    if (context.mounted) {
                      Navigator.of(context, rootNavigator: true).pop();
                    }
                  } catch (_) {
                    if (context.mounted) {
                      AppSnackBar.showError(context, '');
                    }
                  }
                },
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final MoodEntryModel entry;
  final VoidCallback onDelete;

  const _EntryTile({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    final time =
        '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      time,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.rating}/5',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                if (entry.labels.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: entry.labels
                        .map(
                          (l) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  scheme.secondaryContainer.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              l,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: scheme.onSecondaryContainer),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (entry.note != null && entry.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.note!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded,
                size: 20, color: scheme.error),
            tooltip: s.moodDeleteEntry,
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(s.moodDeleteConfirm),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(s.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.error,
                      ),
                      child: Text(s.moodDeleteEntry),
                    ),
                  ],
                ),
              );
              if (confirmed == true) onDelete();
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
