import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/core/config/remote_config_keys.dart';
import 'package:mythdusk/core/config/remote_config_values.dart';

void main() {
  test('falls back to client defaults when Firebase is not ready', () {
    expect(RemoteConfigValues.battlePassEnabled, isFalse);
    expect(RemoteConfigValues.starterPackEnabled, isTrue);
    expect(RemoteConfigValues.defeatContinueEnabled, isTrue);
    expect(
      RemoteConfigValues.boolFor(RemoteConfigKeys.useServerSettlement),
      isTrue,
    );
  });
}
