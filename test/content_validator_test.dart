import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/validate_content.dart';

void main() {
  test('all shipped content references are valid', () {
    final result = ContentValidator(Directory.current).validate();

    expect(result.errors, isEmpty, reason: result.errors.join('\n'));
    expect(result.chapterCount, 10);
    expect(result.nodeCount, 200);
  });
}
