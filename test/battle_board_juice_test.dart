import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/features/battle/domain/battle_state.dart';
import 'package:mythdusk/features/battle/presentation/match_collect_fx.dart';
import 'package:mythdusk/features/battle/presentation/match_collect_overlay.dart';

void main() {
  group('capMatchCollectParticles', () {
    MatchCollectParticle p(int id) => MatchCollectParticle(
          id: id,
          resourceId: 'mana',
          startGlobal: Offset.zero,
        );

    test('returns all when under cap', () {
      final input = [p(0), p(1), p(2)];
      expect(capMatchCollectParticles(input), input);
    });

    test('samples evenly when over cap', () {
      final input = [for (var i = 0; i < 24; i++) p(i)];
      final capped = capMatchCollectParticles(input, max: 12);
      expect(capped, hasLength(12));
      expect(capped.first.id, 0);
      expect(capped.last.id, lessThan(24));
      expect(capped.map((e) => e.id).toSet(), hasLength(12));
    });
  });

  group('BattleController juice timings', () {
    test('cascade steps are snappier than swap', () {
      expect(
        BattleController.clearDuration.inMilliseconds,
        lessThan(280),
      );
      expect(
        BattleController.fallDuration.inMilliseconds,
        lessThan(300),
      );
      expect(
        BattleController.swapDuration.inMilliseconds,
        lessThanOrEqualTo(180),
      );
    });
  });

  group('matchCollectFlightGlobal', () {
    test('starts and ends on the lerp endpoints', () {
      const start = Offset(10, 20);
      const end = Offset(110, 220);
      expect(
        matchCollectFlightGlobal(
          startGlobal: start,
          endGlobal: end,
          t: 0,
          arcLift: 40,
        ),
        start,
      );
      expect(
        matchCollectFlightGlobal(
          startGlobal: start,
          endGlobal: end,
          t: 1,
          arcLift: 40,
        ),
        end,
      );
    });

    test('midpoint arcs upward', () {
      const start = Offset(0, 100);
      const end = Offset(100, 100);
      final mid = matchCollectFlightGlobal(
        startGlobal: start,
        endGlobal: end,
        t: 0.5,
        arcLift: 40,
      );
      expect(mid.dx, 50);
      expect(mid.dy, lessThan(100));
    });
  });
}
