#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:io';

const _maxBundledBytes = 80 * 1024 * 1024;
const _maxSingleAssetBytes = 2 * 1024 * 1024;

void main() {
  final root = _findRepoRoot();
  final entries = _assetEntries(root);
  final files = <String, File>{};
  final errors = <String>[];

  for (final entry in entries) {
    final path = '${root.path}/$entry';
    final type = FileSystemEntity.typeSync(path);
    if (type == FileSystemEntityType.file) {
      files[File(path).absolute.path] = File(path);
      continue;
    }
    if (type != FileSystemEntityType.directory) {
      errors.add('missing pubspec asset entry: $entry');
      continue;
    }
    for (final entity in Directory(path).listSync()) {
      if (entity is File) files[entity.absolute.path] = entity;
    }
  }

  var total = 0;
  for (final file in files.values) {
    final bytes = file.lengthSync();
    total += bytes;
    final relative = file.path.substring(root.path.length + 1);
    final lower = relative.toLowerCase();
    if (bytes > _maxSingleAssetBytes) {
      errors.add(
        '$relative is ${_formatBytes(bytes)}; single-asset limit is '
        '${_formatBytes(_maxSingleAssetBytes)}',
      );
    }
    if (lower.contains('_bak') || lower.contains('deprecated')) {
      errors.add('$relative looks development-only but is bundled');
    }
  }

  if (total > _maxBundledBytes) {
    errors.add(
      'bundle is ${_formatBytes(total)}; budget is '
      '${_formatBytes(_maxBundledBytes)}',
    );
  }

  if (errors.isNotEmpty) {
    for (final error in errors) {
      stderr.writeln('ASSET BUDGET: $error');
    }
    stderr.writeln('asset budget: ${errors.length} issue(s)');
    exit(1);
  }

  print(
    'asset budget: OK '
    '(${files.length} files, ${_formatBytes(total)} / '
    '${_formatBytes(_maxBundledBytes)})',
  );
}

List<String> _assetEntries(Directory root) {
  final lines = File('${root.path}/pubspec.yaml').readAsLinesSync();
  final entryPattern = RegExp(r'^\s+-\s+(assets/\S+)\s*$');
  return [
    for (final line in lines)
      if (entryPattern.firstMatch(line) case final match?) match.group(1)!,
  ];
}

String _formatBytes(int bytes) =>
    '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MiB';

Directory _findRepoRoot() {
  var directory = Directory.current;
  while (true) {
    if (File('${directory.path}/pubspec.yaml').existsSync()) return directory;
    final parent = directory.parent;
    if (parent.path == directory.path) return Directory.current;
    directory = parent;
  }
}
