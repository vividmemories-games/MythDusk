import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/core/config/app_flavor.dart';

void main() {
  test('single production flavor name', () {
    expect(AppFlavor.name, 'prod');
  });

  test('showQaTools is true in debug test runs only', () {
    expect(kDebugMode, isTrue);
    expect(AppFlavor.showQaTools, isTrue);
  });
}
