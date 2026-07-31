/// First-battle teaching beats (profile-persisted).
abstract final class BattleTutorial {
  static const beatMatchResources = 'match_resources';
  static const beatAp = 'ap';
  static const beatSkills = 'skills';
  static const beatMoves = 'moves';
  static const beatIntent = 'intent';

  static const orderedBeats = [
    beatMatchResources,
    beatAp,
    beatSkills,
    beatMoves,
    beatIntent,
  ];

  static const captions = {
    beatMatchResources:
        'Matches fill resources — they do not damage the enemy.',
    beatAp: 'Matches also grant AP. Skills spend both resources and AP.',
    beatSkills: 'When costs are met, skills glow gold. Tap to cast.',
    beatMoves: 'Each swap costs 1 Move. At 0 Moves, the enemy acts.',
    beatIntent: 'The badge shows the enemy\'s next action. Plan around it.',
  };

  static String? nextBeat(Set<String> seen) {
    for (final id in orderedBeats) {
      if (!seen.contains(id)) return id;
    }
    return null;
  }
}
