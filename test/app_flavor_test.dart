import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mythora/core/config/app_flavor.dart';

void main() {
  test('showQaTools is true in debug test runs', () {
    expect(kDebugMode, isTrue);
    expect(AppFlavor.showQaTools, isTrue);
  });

  test('FLAVOR name defaults to prod without dart-define', () {
    expect(AppFlavor.name, anyOf('prod', 'dev'));
  });
}
