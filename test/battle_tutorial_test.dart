import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/features/battle/domain/battle_tutorial.dart';

void main() {
  test('nextBeat walks ordered list then returns null', () {
    expect(BattleTutorial.nextBeat({}), BattleTutorial.beatMatchResources);
    expect(
      BattleTutorial.nextBeat({BattleTutorial.beatMatchResources}),
      BattleTutorial.beatAp,
    );
    expect(
      BattleTutorial.nextBeat(BattleTutorial.orderedBeats.toSet()),
      isNull,
    );
  });

  test('every beat has a caption', () {
    for (final id in BattleTutorial.orderedBeats) {
      expect(BattleTutorial.captions[id], isNotEmpty);
    }
  });
}
