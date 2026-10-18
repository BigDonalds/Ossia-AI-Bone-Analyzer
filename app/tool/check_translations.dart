// Checks the translations in lib/l10n before a build does, in plain words.
//
//   dart run tool/check_translations.dart
//
// Run it from the app folder after editing app_de.arb or app_ar.arb. It reads
// app_en.arb as the master list and, for every other language, reports:
//
//  - a file that is no longer valid (usually a missing comma or quote),
//  - lines that are missing (the app would show English there),
//  - lines whose name is not in the English file (a typo in the name),
//  - a {placeholder} that went missing or was renamed (the number or name
//    would vanish from the sentence, or the build would fail),
//  - a number sentence ({count, plural, ...}) without its other{...} form,
//  - curly brackets that don't pair up.
//
// Nothing is changed. It exits with 1 when something needs fixing.
//
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

const String dir = 'lib/l10n';
const String template = 'app_en.arb';

/// A {name} or {name, ...} that refers to a value, rather than the {...} that
/// holds a plural form (which follows `=1`, `one`, `other` and so on).
final RegExp placeholderUse = RegExp(r'(?<![=\w])\{(\w+)\s*[},]');

int problems = 0;

void problem(String lang, String key, String what) {
  problems++;
  print('  [$lang] $key: $what');
}

Map<String, dynamic>? load(File f) {
  final String text = f.readAsStringSync();
  try {
    return jsonDecode(text) as Map<String, dynamic>;
  } on FormatException catch (e) {
    problems++;
    final int? at = e.offset;
    // Editors count lines, not characters.
    final String where = at == null
        ? ''
        : ' around line ${'\n'.allMatches(text.substring(0, at.clamp(0, text.length))).length + 1}'
            ' (often a missing comma or " on the line before)';
    print('  ${f.uri.pathSegments.last} is not valid any more$where.');
    return null;
  }
}

bool balanced(String s) {
  int depth = 0;
  for (final int unit in s.codeUnits) {
    if (unit == 0x7B) depth++;
    if (unit == 0x7D && --depth < 0) return false;
  }
  return depth == 0;
}

void main() {
  final Directory d = Directory(dir);
  if (!d.existsSync()) {
    print('Run this from the app folder (the one with pubspec.yaml).');
    exit(2);
  }

  final Map<String, dynamic>? en = load(File('$dir/$template'));
  if (en == null) exit(1);
  final Iterable<String> keys = en.keys.where((String k) => !k.startsWith('@'));

  Set<String> declared(String key) {
    final Object? meta = en['@$key'];
    final Object? ph = meta is Map<String, dynamic> ? meta['placeholders'] : null;
    return ph is Map<String, dynamic> ? ph.keys.toSet() : <String>{};
  }

  final List<File> others = d
      .listSync()
      .whereType<File>()
      .where((File f) => f.path.endsWith('.arb') && !f.path.endsWith(template))
      .toList()
    ..sort((File a, File b) => a.path.compareTo(b.path));

  print('${keys.length} lines in $template');
  for (final File f in others) {
    final String name = f.uri.pathSegments.last;
    final Map<String, dynamic>? arb = load(f);
    if (arb == null) continue;
    final String lang = (arb['@@locale'] as String?) ??
        name.substring(4, name.length - 4);
    final int before = problems;

    final List<String> missing = <String>[
      for (final String k in keys)
        if (arb[k] is! String || (arb[k] as String).trim().isEmpty) k,
    ];
    if (missing.isNotEmpty) {
      problems += missing.length;
      print('  [$lang] ${missing.length} missing (shown in English): '
          '${missing.take(12).join(', ')}${missing.length > 12 ? ', …' : ''}');
    }

    for (final MapEntry<String, dynamic> e in arb.entries) {
      final String key = e.key;
      if (key.startsWith('@')) continue;
      if (!en.containsKey(key)) {
        problem(lang, key, 'not in $template (check the spelling of the name)');
        continue;
      }
      final Object? value = e.value;
      if (value is! String) continue;
      final String english = en[key] as String;

      if (!balanced(value)) {
        problem(lang, key, 'the { and } brackets don’t pair up');
        continue;
      }
      final Set<String> want = declared(key);
      final Set<String> used = <String>{
        for (final RegExpMatch m in placeholderUse.allMatches(value)) m[1]!,
      };
      for (final String p in want.difference(used)) {
        problem(lang, key, '{$p} is missing — keep it exactly as in English');
      }
      for (final String p in used.difference(want)) {
        problem(lang, key, '{$p} is not a value this line has — '
            'it should be one of: ${want.isEmpty ? '(none)' : want.map((String w) => '{$w}').join(' ')}');
      }
      if (english.contains(RegExp(r',\s*plural\s*,'))) {
        if (!value.contains(RegExp(r',\s*plural\s*,'))) {
          problem(lang, key, 'English counts here ({…, plural, …}); keep that shape');
        } else if (!value.contains(RegExp(r'\bother\s*\{'))) {
          problem(lang, key, 'needs an other{…} form, used for any number not listed');
        }
      }
    }

    final int found = problems - before;
    print(found == 0 ? '$name: all good' : '$name: $found to fix');
  }

  print(problems == 0
      ? 'No problems. Run `flutter gen-l10n` (or just build) to use them.'
      : '$problems problem(s) found.');
  exit(problems == 0 ? 0 : 1);
}
