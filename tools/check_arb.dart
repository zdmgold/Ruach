// Fails the build if any ARB file differs from the English template in its
// keys or in its placeholders. Run from the repository root:
//
//   dart tools/check_arb.dart
//
// The template is app/lib/l10n/app_en.arb. Before it exists (it arrives with
// batch p6a) the check passes with a note.
import 'dart:convert';
import 'dart:io';

const _dir = 'app/lib/l10n';
const _template = 'app_en.arb';

final _placeholder = RegExp(r'\{(\w+)[,}]');

Map<String, Object?> _read(File file) =>
    jsonDecode(file.readAsStringSync()) as Map<String, Object?>;

Set<String> _keys(Map<String, Object?> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

Set<String> _placeholders(Object? value) {
  if (value is! String) return <String>{};
  return _placeholder.allMatches(value).map((m) => m.group(1)!).toSet();
}

void main() {
  final directory = Directory(_dir);
  final templateFile = File('$_dir/$_template');
  if (!directory.existsSync() || !templateFile.existsSync()) {
    stdout.writeln('check_arb: no template yet ($_dir/$_template); nothing to compare.');
    return;
  }

  final template = _read(templateFile);
  final templateKeys = _keys(template);
  final problems = <String>[];

  final others = directory
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.arb') && !f.path.endsWith(_template))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in others) {
    final arb = _read(file);
    final keys = _keys(arb);

    for (final missing in templateKeys.difference(keys)) {
      problems.add('${file.path}: missing key "$missing"');
    }
    for (final extra in keys.difference(templateKeys)) {
      problems.add('${file.path}: extra key "$extra"');
    }
    for (final key in templateKeys.intersection(keys)) {
      final want = _placeholders(template[key]);
      final have = _placeholders(arb[key]);
      if (want.length != have.length || !want.containsAll(have)) {
        problems.add(
          '${file.path}: placeholders for "$key" are $have, template has $want',
        );
      }
    }
  }

  if (problems.isEmpty) {
    stdout.writeln(
      'check_arb: ${others.length} translation file(s) match the template '
      '(${templateKeys.length} keys).',
    );
    return;
  }

  stderr.writeln('check_arb: translation files differ from the template.');
  for (final problem in problems) {
    stderr.writeln('  $problem');
  }
  exit(1);
}
