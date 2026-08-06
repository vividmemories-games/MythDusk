#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:io';

/// Validates MythDusk docs: relative markdown links + code consistency checks.
///
/// Run: `dart run tool/check_docs.dart`
void main() {
  final root = _findRepoRoot();
  final docsDir = Directory('${root.path}/docs');
  if (!docsDir.existsSync()) {
    stderr.writeln('docs/ not found at ${docsDir.path}');
    exit(1);
  }

  var errors = 0;
  errors += _checkMarkdownLinks(docsDir);
  errors += _checkMarkdownLinksInFile(File('${root.path}/README.md'), root);
  errors += _checkCodeConsistency(root);

  if (errors == 0) {
    print('docs check: OK');
    exit(0);
  }
  stderr.writeln('docs check: $errors issue(s)');
  exit(1);
}

Directory _findRepoRoot() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync() &&
        Directory('${dir.path}/docs').existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      return Directory.current;
    }
    dir = parent;
  }
}

final _mdLink = RegExp(r'\[([^\]]*)\]\(([^)]+)\)');

int _checkMarkdownLinks(Directory docsDir) {
  final files = docsDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.md'))
      .toList();

  print('Checking ${files.length} docs markdown files…');
  var errors = 0;
  for (final file in files) {
    errors += _checkMarkdownLinksInFile(file, file.parent);
  }
  return errors;
}

int _checkMarkdownLinksInFile(File file, Directory baseDir) {
  if (!file.existsSync()) {
    stderr.writeln('MISSING: ${file.path}');
    return 1;
  }

  var errors = 0;
  final text = file.readAsStringSync();
  for (final match in _mdLink.allMatches(text)) {
    var target = match.group(2)!.trim();
    if (target.startsWith('http://') ||
        target.startsWith('https://') ||
        target.startsWith('mailto:') ||
        target.startsWith('#')) {
      continue;
    }
    if (target.contains(' ')) {
      target = target.split(RegExp(r'\s+')).first;
    }
    final pathOnly = target.split('#').first;
    if (pathOnly.isEmpty) continue;

    final abs = File.fromUri(baseDir.uri.resolve(pathOnly));
    if (!abs.existsSync()) {
      final rel = file.path;
      stderr.writeln('BROKEN LINK in $rel: ($target)');
      errors++;
    }
  }
  return errors;
}

int _checkCodeConsistency(Directory root) {
  var errors = 0;

  void requireContains(
    String relativePath,
    List<String> needles,
    String label,
  ) {
    final file = File('${root.path}/$relativePath');
    if (!file.existsSync()) {
      stderr.writeln('MISSING FILE for $label: $relativePath');
      errors++;
      return;
    }
    final text = file.readAsStringSync();
    for (final n in needles) {
      if (!text.contains(n)) {
        stderr.writeln('CONSISTENCY ($label): expected `$n` in $relativePath');
        errors++;
      }
    }
  }

  requireContains(
    'lib/features/heroes/domain/hero_def.dart',
    ['mage', 'knight', 'Fireball', 'Basic Slash'],
    'heroes',
  );
  requireContains(
    'docs/01_Game_Design/Heroes.md',
    ['mage', 'knight', 'Fireball', 'Basic Slash'],
    'heroes-doc',
  );

  requireContains(
    'lib/features/battle/domain/enemy_def.dart',
    ['goblin', 'Nick', 'Slash', 'Heavy Swing', 'weight: 45'],
    'enemies',
  );
  requireContains(
    'docs/01_Game_Design/Enemies.md',
    ['goblin', 'Nick', 'Slash', 'Heavy Swing', '45'],
    'enemies-doc',
  );

  requireContains(
    'lib/core/theme/app_theme.dart',
    ['0xFF0B1C24', '0xFFD4A24C', 'tileRed'],
    'theme',
  );
  requireContains(
    'docs/02_Design_System/Theme.md',
    ['#0B1C24', '#D4A24C', 'tileRed'],
    'theme-doc',
  );

  requireContains(
    'lib/features/battle/domain/battle_state.dart',
    [
      'clearDuration = Duration(milliseconds: 240)',
      'fallDuration = Duration(milliseconds: 280)',
      'spawnDuration = Duration(milliseconds: 300)',
    ],
    'animations',
  );
  requireContains(
    'docs/02_Design_System/Animations.md',
    ['240ms', '280ms', '300ms'],
    'animations-doc',
  );

  requireContains(
    'lib/features/profile/providers/mock_profile_provider.dart',
    ['coins = 500', 'gems = 50'],
    'economy',
  );
  requireContains(
    'docs/01_Game_Design/Economy.md',
    ['500', '50'],
    'economy-doc',
  );

  requireContains(
    'lib/core/router/app_router.dart',
    ["path: '/'", "path: '/battle/:nodeId'", "path: '/campaign'"],
    'routes',
  );
  requireContains(
    'docs/04_Technical/Architecture.md',
    ['`/`', '`/battle/:nodeId`', '`/campaign`'],
    'routes-doc',
  );

  return errors;
}
