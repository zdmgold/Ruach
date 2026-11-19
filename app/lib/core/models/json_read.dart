/// Tolerant readers for decoded JSON. Saved files can be old, new, hand
/// edited or damaged, so a wrong type or a missing key gives the fallback
/// instead of an exception (blueprint section 4, persistence).
library;

/// A decoded JSON object, or an empty map if [value] is not one.
Map<String, Object?> asJsonMap(Object? value) {
  if (value is Map<Object?, Object?>) {
    final Map<String, Object?> result = <String, Object?>{};
    value.forEach((Object? k, Object? v) {
      if (k is String) result[k] = v;
    });
    return result;
  }
  return <String, Object?>{};
}

List<Object?> asJsonList(Object? value) =>
    value is List<Object?> ? value : <Object?>[];

int readInt(Object? value, int fallback) {
  if (value is int) return value;
  if (value is double && value.isFinite) return value.round();
  return fallback;
}

double readDouble(Object? value, double fallback) {
  if (value is num && value.isFinite) return value.toDouble();
  return fallback;
}

bool readBool(Object? value, bool fallback) => value is bool ? value : fallback;

String readString(Object? value, String fallback) =>
    value is String ? value : fallback;

String? readStringOrNull(Object? value) => value is String ? value : null;

/// A set of strings from a JSON list; entries that are not strings are
/// dropped.
Set<String> readStringSet(Object? value) => <String>{
      for (final Object? item in asJsonList(value))
        if (item is String) item,
    };

/// A map of string to int; entries with a wrong type are dropped.
Map<String, int> readIntMap(Object? value) {
  final Map<String, int> result = <String, int>{};
  asJsonMap(value).forEach((String k, Object? v) {
    if (v is int) {
      result[k] = v;
    } else if (v is double && v.isFinite) {
      result[k] = v.round();
    }
  });
  return result;
}

/// A map of string to string; entries with a wrong type are dropped.
Map<String, String> readStringMap(Object? value) {
  final Map<String, String> result = <String, String>{};
  asJsonMap(value).forEach((String k, Object? v) {
    if (v is String) result[k] = v;
  });
  return result;
}

/// The same map with keys in sorted order, so encoding the same data always
/// gives the same text.
Map<String, T> sortedMap<T>(Map<String, T> map) {
  final List<String> keys = map.keys.toList()..sort();
  return <String, T>{for (final String k in keys) k: map[k] as T};
}

T enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  if (name is String) {
    for (final T value in values) {
      if (value.name == name) return value;
    }
  }
  return fallback;
}
