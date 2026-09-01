import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/features/auth/domain/link_conflict.dart';
import 'package:mythdusk/features/profile/providers/mock_profile_provider.dart';

void main() {
  test('link conflict keeps guest or switches — never max coins', () {
    const guest = PlayerProfile(coins: 10, gems: 1);
    const cloud = PlayerProfile(coins: 900, gems: 80);

    expect(
      LinkConflictResolver.choose(
        guest: guest,
        existingCloud: cloud,
        choice: LinkConflictChoice.keepGuest,
      ).coins,
      10,
    );
    expect(
      LinkConflictResolver.choose(
        guest: guest,
        existingCloud: cloud,
        choice: LinkConflictChoice.switchToExisting,
      ).coins,
      900,
    );
  });
}
