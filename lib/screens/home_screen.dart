import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/feedback_config.dart';
import '../config/update_announcement_config.dart';
import '../models/media_entry.dart';
import '../state/entries_provider.dart';
import '../state/feedback_prompt_provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_mode_controller.dart';
import '../utils/format.dart';
import '../utils/open_link.dart';
import 'add_media_screen.dart';
import 'feedback_screen.dart';
import 'guide_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Timer? _dateTimer;
  bool _announcementCheckStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dateTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => context.read<EntriesProvider>().refreshDate(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_announcementCheckStarted) {
        _announcementCheckStarted = true;
        unawaited(_showUpdateAnnouncementIfNeeded());
      }
    });
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

  Future<void> _showUpdateAnnouncementIfNeeded() async {
    SharedPreferences preferences;
    try {
      preferences = await SharedPreferences.getInstance();
    } on PlatformException catch (error, stackTrace) {
      _reportAnnouncementError(error, stackTrace);
      return;
    }

    if (!mounted ||
        preferences.getInt(updateAnnouncementPreferenceKey) ==
            updateAnnouncementRevision) {
      return;
    }

    final action = await showDialog<_UpdateAnnouncementAction>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Heads up!'),
          content: const Text(updateAnnouncementMessage),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext)
                      .pop(_UpdateAnnouncementAction.dismiss),
              child: const Text('Got It, Thanks Austin!'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(dialogContext)
                      .pop(_UpdateAnnouncementAction.leaveReview),
              child: const Text('Leave a Review'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;

    bool saved;
    try {
      saved = await preferences.setInt(
        updateAnnouncementPreferenceKey,
        updateAnnouncementRevision,
      );
    } on PlatformException catch (error, stackTrace) {
      _reportAnnouncementError(error, stackTrace);
      return;
    }
    if (!mounted) return;
    if (!saved) {
      _showAnnouncementError(
        'Could not save the update notice. It may appear again next time.',
      );
      return;
    }

    if (action == _UpdateAnnouncementAction.leaveReview) {
      final feedbackProvider = context.read<FeedbackPromptProvider>();
      final opened = await openLink(reviewFormUrl);
      if (!mounted) return;
      if (opened) {
        await feedbackProvider.markReviewed();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't open the form. Please try again."),
          ),
        );
      }
    }
  }

  void _reportAnnouncementError(Object error, StackTrace stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'Point Tracker update announcement',
      ),
    );
    _showAnnouncementError(
      'Could not load the update notice. Please try again later.',
    );
  }

  void _showAnnouncementError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
            tooltip: 'Quick Guide',
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(builder: (_) => const GuideScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Feedback',
            icon: const Icon(Icons.rate_review_outlined, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(builder: (_) => const FeedbackScreen()),
              );
            },
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
                  _TotalCard(
                    total: entries.todaysTotal,
                    matterportBonus: entries.todaysMatterportBonus,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 68,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 28),
                      label: const Text('Add', style: TextStyle(fontSize: 20)),
                      onPressed: _addMedia,
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

  Future<void> _addMedia() async {
    final entriesProvider = context.read<EntriesProvider>();
    final feedbackProvider = context.read<FeedbackPromptProvider>();
    final previousIds = entriesProvider.todaysEntries
        .map((entry) => entry.id)
        .toSet();
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const AddMediaScreen()),
    );
    if (!mounted || result != true) return;

    final addedEntries = entriesProvider.todaysEntries
        .where((entry) => !previousIds.contains(entry.id))
        .toList();
    if (addedEntries.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added ${formatExactPoints(addedEntries.first.points)} pts',
          ),
        ),
      );
    }

    if (feedbackProvider.shouldShowPrompt) {
      await _showFeedbackPrompt(feedbackProvider);
    }
  }

  Future<void> _showFeedbackPrompt(
    FeedbackPromptProvider feedbackProvider,
  ) async {
    final action = await showDialog<_FeedbackPromptAction>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enjoying Point Tracker?'),
        content: const Text(
          'Would you take a moment to rate the app and tell us what you think?',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
            ),
            onPressed: () =>
                Navigator.of(dialogContext)
                    .pop(_FeedbackPromptAction.leaveReview),
            child: const Text('Leave a Review'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext)
                    .pop(_FeedbackPromptAction.maybeLater),
            child: const Text('Maybe Later'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_FeedbackPromptAction.neverAsk),
            child: const Text("Don't Ask Again"),
          ),
        ],
      ),
    );
    if (!mounted || action == null) return;

    switch (action) {
      case _FeedbackPromptAction.maybeLater:
        await feedbackProvider.markMaybeLater();
        break;
      case _FeedbackPromptAction.neverAsk:
        await feedbackProvider.markNeverAsk();
        break;
      case _FeedbackPromptAction.leaveReview:
        final opened = await openLink(reviewFormUrl);
        if (!mounted) return;
        if (opened) {
          await feedbackProvider.markReviewed();
        } else {
          await feedbackProvider.markMaybeLater();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Couldn't open the form. Please try again."),
            ),
          );
        }
    }
  }
}

enum _FeedbackPromptAction { leaveReview, maybeLater, neverAsk }

enum _UpdateAnnouncementAction { dismiss, leaveReview }

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.total, required this.matterportBonus});

  final double total;
  final int matterportBonus;

  @override
  Widget build(BuildContext context) {
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
              'Matterport Bonus: \$$matterportBonus',
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
    final groupedEntries =
        <(String, String?, String?, double), List<MediaEntry>>{};
    for (final entry in entries) {
      groupedEntries
          .putIfAbsent((
            entry.label,
            entry.sqftRange,
            entry.acres,
            entry.points,
          ), () => [])
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
            final headerColor = Theme.of(context).brightness == Brightness.dark
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
                              if (mediaEntry.acres != null)
                                'Acres: ${mediaEntry.acres}',
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
