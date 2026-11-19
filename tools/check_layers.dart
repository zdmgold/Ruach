// Fails the build if the pure-Dart core imports anything outside itself that
// would tie it to Flutter, the platform, or a higher layer (blueprint
// section 4). Run from the repository root:
//
//   dart tools/check_layers.dart
import 'dart:io';

final List<RegExp> _forbidden = <RegExp>[
  RegExp(r'''import\s+['"]package:flutter/'''),
  RegExp(r'''import\s+['"]package:flame'''),
  RegExp(r'''import\s+['"]dart:ui['"]'''),
  RegExp(r'''import\s+['"]dart:io['"]'''),
  RegExp(r'''import\s+['"]dart:html['"]'''),
  RegExp(
    r'''import\s+['"]package:ruach/(platform|providers|game|screens|widgets|theme|utils|l10n)/''',
  ),
];

void main() {
  final Directory core = Directory('app/lib/core');
  if (!core.existsSync()) {
    stdout.writeln('No core folder yet.');
    return;
  }
  final List<String> problems = <String>[];
  for (final FileSystemEntity entity in core.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final List<String> lines = entity.readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      for (final RegExp pattern in _forbidden) {
        if (pattern.hasMatch(lines[i])) {
          problems.add('${entity.path}:${i + 1}: ${lines[i].trim()}');
          break;
        }
      }
    }
  }
  if (problems.isNotEmpty) {
    stderr.writeln('Core must stay pure Dart. Forbidden imports:');
    problems.forEach(stderr.writeln);
    exit(1);
  }
  stdout.writeln('Layering OK.');
}
