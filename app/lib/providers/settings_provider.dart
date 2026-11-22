import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:ruach/core/models/settings.dart';
import 'package:ruach/core/ports/file_store.dart';

/// The player's preferences, kept in the key-value store. Changes apply at
/// once and are written after.
final class SettingsProvider extends ValueNotifier<Settings> {
  SettingsProvider(this._store, {this.onError}) : super(const Settings());

  static const String storageKey = 'settings';

  final KeyValueStore _store;
  final void Function(String message)? onError;
  Future<void> _tail = Future<void>.value();

  /// Reads saved settings. A missing or damaged value leaves the defaults.
  Future<void> load() async {
    try {
      final String? text = await _store.getString(storageKey);
      if (text != null) value = Settings.fromJson(jsonDecode(text));
    } on Object catch (error) {
      onError?.call('settings could not be read: $error');
    }
  }

  /// Applies [change] to the current settings and saves the result.
  Future<void> update(Settings Function(Settings current) change) {
    value = change(value);
    final String text = jsonEncode(value.toJson());
    _tail = _tail.then((_) async {
      try {
        await _store.setString(storageKey, text);
      } on Object catch (error) {
        onError?.call('settings could not be saved: $error');
      }
    });
    return _tail;
  }

  /// Completes when every earlier save has finished.
  Future<void> flush() => _tail;
}
