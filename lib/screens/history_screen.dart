import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/media_entry.dart';
import '../state/entries_provider.dart';
import '../utils/format.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final days = context.watch<EntriesProvider>().entriesByDay.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: days.isEmpty
                ? const Center(child: Text('No history yet'))
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      for (final day in days)
                        Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          clipBehavior: Clip.antiAlias,
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            title: Text(
                              _longDate(day.key),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${day.value.length} ${day.value.length == 1 ? 'item' : 'items'}',
                            ),
                            trailing: Text(
                              formatTotal(_dayTotal(day.value)),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            children: [
                              const Divider(height: 1),
                              for (final entry in day.value)
                                _HistoryEntryRow(entry: entry),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  double _dayTotal(List<MediaEntry> entries) =>
      entries.fold(0, (total, entry) => total + entry.points);
}

class _HistoryEntryRow extends StatelessWidget {
  const _HistoryEntryRow({required this.entry});

  final MediaEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.photo_camera_outlined, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.label,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  [
                    if (entry.sqftRange != null) entry.sqftRange!,
                    if (entry.acres != null) 'Acres: ${entry.acres}',
                    _time(entry.timestamp),
                  ].join(' • '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatExactPoints(entry.points),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

String _longDate(DateTime date) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
}

String _time(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour < 12 ? 'AM' : 'PM';
  return '$hour:$minute $period';
}
