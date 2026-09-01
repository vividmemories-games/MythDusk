import '../../profile/providers/mock_profile_provider.dart';

enum LinkConflictChoice { keepGuest, switchToExisting }

/// Account-link collision: never merge by max(coins/gems).
abstract final class LinkConflictResolver {
  static PlayerProfile choose({
    required PlayerProfile guest,
    required PlayerProfile existingCloud,
    required LinkConflictChoice choice,
  }) {
    return switch (choice) {
      LinkConflictChoice.keepGuest => guest,
      LinkConflictChoice.switchToExisting => existingCloud,
    };
  }

  static int mergedCoins(int local, int cloud) {
    throw UnsupportedError('Never max() or sum coins on link conflict.');
  }
}
