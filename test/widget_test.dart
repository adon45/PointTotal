import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoot_points/main.dart';
import 'package:shoot_points/models/media_entry.dart';
import 'package:shoot_points/config/feedback_config.dart';
import 'package:shoot_points/state/entries_provider.dart';
import 'package:shoot_points/state/feedback_prompt_provider.dart';
import 'package:shoot_points/theme/app_theme.dart';
import 'package:shoot_points/theme/theme_mode_controller.dart';
import 'package:shoot_points/utils/format.dart';

void main() {
  test('point formatting preserves exact values and rounds totals only', () {
    expect(formatExactPoints(0.25), '0.25');
    expect(formatExactPoints(0.5), '0.50');
    expect(formatExactPoints(1.0), '1.00');
    expect(formatExactPoints(0.0667), '0.0667');
    expect(formatExactPoints(0.006666), '0.006666');
    expect(formatExactPoints(0.0556), '0.0556');
    expect(formatTotal(0.0667 + 0.006666), '0.07');
  });

  testWidgets('home screen displays the daily total and empty state', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final provider = EntriesProvider();
    final themeController = ThemeModeController();
    final feedbackProvider = await _loadFeedbackPromptProvider();
    await provider.load();
    await themeController.load();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          ChangeNotifierProvider.value(value: feedbackProvider),
          ChangeNotifierProvider.value(value: themeController),
        ],
        child: const ShootPointsApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Point Tracker'), findsOneWidget);
    expect(find.text('0.00'), findsOneWidget);
    expect(find.text('No media submitted yet'), findsOneWidget);
    expect(find.text('Created by Austin Donovan'), findsOneWidget);
  });

  testWidgets('Homes selection saves its exact points and range', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final provider = EntriesProvider();
    final themeController = ThemeModeController();
    final feedbackProvider = await _loadFeedbackPromptProvider();
    await provider.load();
    await themeController.load();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          ChangeNotifierProvider.value(value: feedbackProvider),
          ChangeNotifierProvider.value(value: themeController),
        ],
        child: const ShootPointsApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    final disabledSubmit = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Submit'),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(disabledSubmit.onPressed, isNull);
    expect(
      disabledSubmit.style!.backgroundColor!.resolve({WidgetState.disabled})!.a,
      lessThan(1),
    );

    await tester.tap(find.text('Homes'));
    await tester.pumpAndSettle();
    expect(find.text('Silver'), findsOneWidget);
    await tester.tap(find.text('Homes'));
    await tester.pumpAndSettle();
    expect(find.text('Silver'), findsNothing);
    await tester.tap(find.text('Homes'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Silver'), 300);
    await tester.tap(find.text('Silver').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Silver w/ Splat'), 300);
    await tester.tap(find.text('Silver w/ Splat'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Up to 2,000 • 0.25 pts'), 300);
    await tester.tap(find.text('Up to 2,000 • 0.25 pts'));
    await tester.pumpAndSettle();
    final readySubmit = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Submit'),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(readySubmit.onPressed, isNotNull);
    expect(readySubmit.style!.backgroundColor!.resolve({})!, AppTheme.accent);
    await tester.scrollUntilVisible(find.text('Submit'), 300);
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.text('0.25'), findsNWidgets(2));
    expect(find.text('Added 0.25 pts'), findsOneWidget);
    expect(provider.todaysEntries.single.sqftRange, 'Up to 2,000');
    expect(
      provider.todaysEntries.single.label,
      'Homes – Silver – Silver w/ Splat',
    );
  });

  testWidgets('goal total turns orange and dark mode preference persists', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final provider = EntriesProvider();
    final themeController = ThemeModeController();
    final feedbackProvider = await _loadFeedbackPromptProvider();
    await provider.load();
    await themeController.load();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          ChangeNotifierProvider.value(value: feedbackProvider),
          ChangeNotifierProvider.value(value: themeController),
        ],
        child: const ShootPointsApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await provider.addEntry(
      MediaEntry.create(
        label: 'Test entry',
        points: 1.0,
        timestamp: DateTime.now(),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<Text>(find.text('1.00'))
          .any((text) => text.style?.color == AppTheme.accent),
      isTrue,
    );

    await tester.tap(find.byTooltip('Switch to dark mode'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Point Tracker').last)).brightness,
      Brightness.dark,
    );
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('point_tracker_dark_mode'), isTrue);
  });

  testWidgets(
    'New Homes Community Splat calculates points from decimal acres',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final provider = EntriesProvider();
      final themeController = ThemeModeController();
      final feedbackProvider = await _loadFeedbackPromptProvider();
      await provider.load();
      await themeController.load();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider.value(value: feedbackProvider),
            ChangeNotifierProvider.value(value: themeController),
          ],
          child: const ShootPointsApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      final root = find.text('New Homes Community Splat');
      await tester.ensureVisible(root);
      await tester.tap(root);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '2.5');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(provider.todaysEntries.single.acres, '2.5');
      expect(provider.todaysEntries.single.points, closeTo(0.0125, 0.0000001));
      expect(
        find.text('New Homes Community Splat\nAcres: 2.5'),
        findsOneWidget,
      );
    },
  );

  testWidgets('Residential Land Splat submits without qualifiers', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final provider = EntriesProvider();
    final themeController = ThemeModeController();
    final feedbackProvider = await _loadFeedbackPromptProvider();
    await provider.load();
    await themeController.load();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          ChangeNotifierProvider.value(value: feedbackProvider),
          ChangeNotifierProvider.value(value: themeController),
        ],
        child: const ShootPointsApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    final root = find.text('Residential Land Splat');
    await tester.ensureVisible(root);
    await tester.tap(root);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Submit'), findsOneWidget);

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(provider.todaysEntries.single.label, 'Residential Land Splat');
    expect(provider.todaysEntries.single.points, 0.25);
  });

  testWidgets('review prompt waits until a successful Home submission', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'feedback_open_count': firstPromptAfterOpens,
    });
    final provider = EntriesProvider();
    final themeController = ThemeModeController();
    final feedbackProvider = await _loadFeedbackPromptProvider();
    await provider.load();
    await themeController.load();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          ChangeNotifierProvider.value(value: feedbackProvider),
          ChangeNotifierProvider.value(value: themeController),
        ],
        child: const ShootPointsApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Enjoying Point Tracker?'), findsNothing);
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    final root = find.text('Residential Land Splat');
    await tester.ensureVisible(root);
    await tester.tap(root);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Enjoying Point Tracker?'), findsOneWidget);
    expect(find.text('Added 0.25 pts'), findsOneWidget);
    await tester.tap(find.text('Maybe Later'));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getInt('feedback_next_prompt_at'),
      firstPromptAfterOpens + repeatPromptEveryOpens,
    );
  });

  testWidgets('Feedback screen offers the two form options', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final provider = EntriesProvider();
    final themeController = ThemeModeController();
    final feedbackProvider = await _loadFeedbackPromptProvider();
    await provider.load();
    await themeController.load();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          ChangeNotifierProvider.value(value: feedbackProvider),
          ChangeNotifierProvider.value(value: themeController),
        ],
        child: const ShootPointsApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Feedback'));
    await tester.pumpAndSettle();

    expect(find.text("We'd love to hear from you"), findsOneWidget);
    expect(find.text('Leave a Review'), findsOneWidget);
    expect(find.text('Make a Suggestion'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNWidgets(2));
  });

  testWidgets('identical entries show a count and delete removes one', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final provider = EntriesProvider();
    final themeController = ThemeModeController();
    final feedbackProvider = await _loadFeedbackPromptProvider();
    await provider.load();
    await themeController.load();

    final now = DateTime.now();
    await provider.addEntry(
      MediaEntry.create(
        label: 'Media Shoots – Gold',
        points: 0.006666,
        timestamp: now,
        sqftRange: 'Up to 2,000',
      ),
    );
    await provider.addEntry(
      MediaEntry.create(
        label: 'Media Shoots – Gold',
        points: 0.006666,
        timestamp: now.add(const Duration(seconds: 1)),
        sqftRange: 'Up to 2,000',
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          ChangeNotifierProvider.value(value: feedbackProvider),
          ChangeNotifierProvider.value(value: themeController),
        ],
        child: const ShootPointsApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(
      find.text('Media Shoots – Gold\nSq Ft: Up to 2,000\n× 2'),
      findsOneWidget,
    );
    expect(find.text('Sq Ft Range'), findsNothing);
    expect(find.text('0.01'), findsNWidgets(2));
    expect(provider.todaysTotal, closeTo(0.013332, 0.0000001));

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete one submission?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(provider.todaysEntries, hasLength(1));
    expect(
      find.text('Media Shoots – Gold\nSq Ft: Up to 2,000'),
      findsOneWidget,
    );
    expect(find.textContaining('× 2'), findsNothing);
    expect(find.text('0.01'), findsNWidgets(2));
    expect(provider.todaysTotal, closeTo(0.006666, 0.0000001));
  });
}

Future<FeedbackPromptProvider> _loadFeedbackPromptProvider() async {
  final provider = FeedbackPromptProvider();
  await provider.load();
  return provider;
}
