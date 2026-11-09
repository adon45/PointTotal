import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoot_points/config/feedback_config.dart';
import 'package:shoot_points/state/feedback_prompt_provider.dart';

void main() {
  test(
    'feedback preferences use defaults and persist prompt choices',
    () async {
      SharedPreferences.setMockInitialValues({});
      final provider = FeedbackPromptProvider();
      await provider.load();

      expect(provider.openCount, 0);
      expect(provider.nextPromptAt, firstPromptAfterOpens);
      expect(provider.shouldShowPrompt, isFalse);

      await provider.recordOpen();
      expect(provider.openCount, 1);
      expect(provider.shouldShowPrompt, isFalse);

      await provider.markMaybeLater();
      expect(provider.nextPromptAt, 1 + repeatPromptEveryOpens);
      await provider.markNeverAsk();
      await provider.markReviewed();

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getInt('feedback_open_count'), 1);
      expect(
        preferences.getInt('feedback_next_prompt_at'),
        1 + repeatPromptEveryOpens,
      );
      expect(preferences.getInt('feedback_last_open_counted_ms'), isNotNull);
      expect(preferences.getBool('feedback_never_ask'), isTrue);
      expect(preferences.getBool('feedback_reviewed'), isTrue);
      expect(provider.shouldShowPrompt, isFalse);
    },
  );

  test('resume counts an open only after the configured interval', () async {
    final oldTimestamp = DateTime.now()
        .subtract(Duration(minutes: resumeCountsAsOpenAfterMinutes + 1))
        .millisecondsSinceEpoch;
    SharedPreferences.setMockInitialValues({
      'feedback_open_count': 4,
      'feedback_last_open_counted_ms': oldTimestamp,
    });
    final provider = FeedbackPromptProvider();
    await provider.load();

    await provider.recordResumeIfDue();

    expect(provider.openCount, 5);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getInt('feedback_last_open_counted_ms'),
      greaterThan(oldTimestamp),
    );
  });
}
