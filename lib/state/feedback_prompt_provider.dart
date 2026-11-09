import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/feedback_config.dart';

class FeedbackPromptProvider extends ChangeNotifier {
  static const _openCountKey = 'feedback_open_count';
  static const _nextPromptAtKey = 'feedback_next_prompt_at';
  static const _neverAskKey = 'feedback_never_ask';
  static const _reviewedKey = 'feedback_reviewed';
  static const _lastOpenCountedMsKey = 'feedback_last_open_counted_ms';

  SharedPreferences? _preferences;
  int _openCount = 0;
  int _nextPromptAt = firstPromptAfterOpens;
  bool _neverAsk = false;
  bool _reviewed = false;
  int _lastOpenCountedMs = 0;
  bool _recordingOpen = false;

  int get openCount => _openCount;

  int get nextPromptAt => _nextPromptAt;

  bool get shouldShowPrompt =>
      !_neverAsk && !_reviewed && _openCount >= _nextPromptAt;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    _preferences = preferences;
    _openCount = preferences.getInt(_openCountKey) ?? 0;
    _nextPromptAt =
        preferences.getInt(_nextPromptAtKey) ?? firstPromptAfterOpens;
    _neverAsk = preferences.getBool(_neverAskKey) ?? false;
    _reviewed = preferences.getBool(_reviewedKey) ?? false;
    _lastOpenCountedMs = preferences.getInt(_lastOpenCountedMsKey) ?? 0;
  }

  Future<void> recordOpen() async {
    await _recordOpenAt(DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> recordResumeIfDue() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final interval = Duration(minutes: resumeCountsAsOpenAfterMinutes);
    if (_recordingOpen || now - _lastOpenCountedMs < interval.inMilliseconds) {
      return;
    }
    await _recordOpenAt(now);
  }

  Future<void> markMaybeLater() async {
    final nextPromptAt = _openCount + repeatPromptEveryOpens;
    final saved = await _requirePreferences().setInt(
      _nextPromptAtKey,
      nextPromptAt,
    );
    if (!saved) {
      throw StateError('Could not save the next feedback prompt threshold.');
    }
    _nextPromptAt = nextPromptAt;
    notifyListeners();
  }

  Future<void> markNeverAsk() async {
    final saved = await _requirePreferences().setBool(_neverAskKey, true);
    if (!saved) {
      throw StateError('Could not save the feedback prompt preference.');
    }
    _neverAsk = true;
    notifyListeners();
  }

  Future<void> markReviewed() async {
    final saved = await _requirePreferences().setBool(_reviewedKey, true);
    if (!saved) {
      throw StateError('Could not save the review preference.');
    }
    _reviewed = true;
    notifyListeners();
  }

  Future<void> _recordOpenAt(int timestamp) async {
    final preferences = _requirePreferences();
    if (_recordingOpen) return;
    _recordingOpen = true;
    try {
      final openCount = _openCount + 1;
      final countSaved = await preferences.setInt(_openCountKey, openCount);
      if (!countSaved) {
        throw StateError('Could not save the feedback open count.');
      }
      final timestampSaved = await preferences.setInt(
        _lastOpenCountedMsKey,
        timestamp,
      );
      if (!timestampSaved) {
        throw StateError('Could not save the last feedback open timestamp.');
      }
      _openCount = openCount;
      _lastOpenCountedMs = timestamp;
      notifyListeners();
    } finally {
      _recordingOpen = false;
    }
  }

  SharedPreferences _requirePreferences() {
    final preferences = _preferences;
    if (preferences == null) {
      throw StateError('FeedbackPromptProvider.load() must be called first.');
    }
    return preferences;
  }
}
