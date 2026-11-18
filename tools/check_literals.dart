// Fails the build if a widget or screen file contains a user-facing string
// literal. Every visible string must come from the generated localizations
// class (blueprint section 8). Run from the repository root:
//
//   dart tools/check_literals.dart
//
// A line that is deliberately allowed carries the marker `// l10n-ok`.
import 'dart:io';

const _scannedDirs = <String>[
  'app/lib/screens',
  'app/lib/widgets',
  'app/lib/game',
];

// Named arguments and constructors that put text in front of the player.
final _patterns = <RegExp>[
  RegExp(r'''\bText\(\s*['"]'''),
  RegExp(r'''\bTextSpan\(\s*text:\s*['"]'''),
  RegExp(r'''\b(label|title|subtitle|hint|hintText|semanticLabel|tooltip|message|text)\s*:\s*['"]'''),
];

void main() {
  final problems = <String>[];

  for (final dir in _scannedDirs) {
    final directory = Directory(dir);
    if (!directory.existsSync()) continue;
    for (final entity in directory.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.contains('// l10n-ok')) continue;
        final trimmed = line.trimLeft();
        if (trimmed.startsWith('//') || trimmed.startsWith('///')) continue;
        for (final pattern in _patterns) {
          if (pattern.hasMatch(line)) {
            problems.add('${entity.path}:${i + 1}: ${line.trim()}');
            break;
          }
        }
      }
    }
  }

  if (problems.isEmpty) {
    stdout.writeln('check_literals: no literal user-facing strings found.');
    return;
  }

  stderr.writeln('check_literals: literal strings found in widget files.');
  stderr.writeln('Move them to the ARB files, or mark a deliberate case with // l10n-ok.');
  for (final problem in problems) {
    stderr.writeln('  $problem');
  }
  exit(1);
}
