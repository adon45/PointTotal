import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/media_entry.dart';
import '../state/entries_provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_mode_controller.dart';
import '../utils/format.dart';
import 'add_media_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Timer? _dateTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dateTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => context.read<EntriesProvider>().refreshDate(),
    );
  }

  @override
  void dispose() {
    _dateTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<EntriesProvider>().refreshDate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<EntriesProvider>();
    final themeMode = context.watch<ThemeModeController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<EntriesProvider>().refreshDate();
    });
    final todaysEntries = entries.todaysEntries;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Point Tracker'),
        actions: [
          IconButton(
            tooltip: themeMode.isDarkMode
                ? 'Switch to light mode'
                : 'Switch to dark mode',
            icon: Icon(
              themeMode.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
            ),
            onPressed: themeMode.toggle,
          ),
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TotalCard(total: entries.todaysTotal),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 68,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 28),
                      label: const Text('Add', style: TextStyle(fontSize: 20)),
                      onPressed: () async {
                        await Navigator.of(context).push<double>(
                          MaterialPageRoute<double>(
                            builder: (_) => const AddMediaScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Submitted Today',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: todaysEntries.isEmpty
                        ? const Center(
                            child: Text(
                              'No media submitted yet',
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        : _SubmittedTable(entries: todaysEntries),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Created by Austin Donovan',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark ? const Color(0xFF172A4D) : AppTheme.primary,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            const Text(
              "Today's Points",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formatTotal(total),
                style:
                    const TextStyle(
                      fontSize: 76,
                      height: 1.05,
                      fontWeight: FontWeight.bold,
                    ).copyWith(
                      color: total >= 1.0 ? AppTheme.accent : Colors.white,
                    ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _shortDate(today),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmittedTable extends StatelessWidget {
  const _SubmittedTable({required this.entries});

  final List<MediaEntry> entries;

  @override
  Widget build(BuildContext context) {
    final groupedEntries = <(String, String?, double), List<MediaEntry>>{};
    for (final entry in entries) {
      groupedEntries
          .putIfAbsent((entry.label, entry.sqftRange, entry.points), () => [])
          .add(entry);
    }
    final groups = groupedEntries.values
        .map((group) => _EntryGroup(group))
        .toList();

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final headerColor =
                Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF172A4D)
                : AppTheme.primary;
            return SizedBox(
              width: constraints.maxWidth,
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(0.62),
                  1: FlexColumnWidth(0.2),
                  2: FlexColumnWidth(0.18),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: headerColor),
                    children: [
                      _tableHeader('Media'),
                      _tableHeader('Points'),
                      _tableHeader(''),
                    ],
                  ),
                  ...groups.map((group) {
                    final mediaEntry = group.representative;
                    return TableRow(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          child: Text(
                            [
                              mediaEntry.label,
                              if (mediaEntry.sqftRange != null)
                                'Sq Ft: ${mediaEntry.sqftRange}',
                              if (group.quantity > 1) '× ${group.quantity}',
                            ].join('\n'),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 12,
                          ),
                          child: Text(formatTotal(group.totalPoints)),
                        ),
                        Center(
                          child: IconButton(
                            tooltip: 'Delete',
                            icon: const Icon(Icons.delete_outline),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                              width: 36,
                              height: 36,
                            ),
                            onPressed: () => _confirmDelete(
                              context,
                              mediaEntry.id,
                              group.quantity,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _tableHeader(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String id,
    int quantity,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete one submission?'),
        content: Text(
          quantity > 1
              ? 'One of the $quantity matching submissions will be removed.'
              : 'This submitted item will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<EntriesProvider>().deleteEntry(id);
    }
  }

}

class _EntryGroup {
  _EntryGroup(this.entries);

  final List<MediaEntry> entries;

  MediaEntry get representative => entries.first;

  int get quantity => entries.length;

  double get totalPoints =>
      entries.fold(0, (total, entry) => total + entry.points);
}

String _shortDate(DateTime date) {
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
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
