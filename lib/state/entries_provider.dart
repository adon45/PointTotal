import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/media_entry.dart';

class EntriesProvider extends ChangeNotifier {
  static const String _storageKey = 'shoot_points_entries';

  List<MediaEntry> _entries = [];
  DateTime _observedDate = _dateOnly(DateTime.now());

  List<MediaEntry> get todaysEntries {
    final today = _dateOnly(DateTime.now());
    return _entries
        .where((entry) => _dateOnly(entry.timestamp) == today)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  double get todaysTotal =>
      todaysEntries.fold(0, (total, entry) => total + entry.points);

  Map<DateTime, List<MediaEntry>> get entriesByDay {
    final grouped = <DateTime, List<MediaEntry>>{};
    for (final entry in _entries) {
      final day = _dateOnly(entry.timestamp);
      grouped.putIfAbsent(day, () => []).add(entry);
    }
    for (final dayEntries in grouped.values) {
      dayEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
    return Map.unmodifiable(grouped);
  }

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final serialized = preferences.getString(_storageKey);
    if (serialized != null) {
      final decoded = jsonDecode(serialized) as List<dynamic>;
      _entries = decoded
          .map((item) => MediaEntry.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    _observedDate = _dateOnly(DateTime.now());
  }

  Future<void> addEntry(MediaEntry entry) async {
    final updatedEntries = [..._entries, entry];
    await _save(updatedEntries);
    _entries = updatedEntries;
    _observedDate = _dateOnly(DateTime.now());
    notifyListeners();
  }

  Future<void> deleteEntry(String id) async {
    final updatedEntries = _entries.where((entry) => entry.id != id).toList();
    if (updatedEntries.length == _entries.length) {
      return;
    }
    await _save(updatedEntries);
    _entries = updatedEntries;
    notifyListeners();
  }

  void refreshDate() {
    final currentDate = _dateOnly(DateTime.now());
    if (currentDate != _observedDate) {
      _observedDate = currentDate;
      notifyListeners();
    }
  }

  Future<void> _save(List<MediaEntry> entries) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _storageKey,
      jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
    if (!saved) {
      throw StateError('Could not save Point Tracker entries.');
    }
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
