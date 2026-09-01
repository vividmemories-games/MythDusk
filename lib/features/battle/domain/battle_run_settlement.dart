/// Pure PvE settlement math. Cloud Functions must match this behavior.
abstract final class BattleRunSettlement {
  static const maxCoinReward = 5000;
  static const schemaVersion = 1;

  static int clampCoinReward(int coinReward) {
    if (coinReward < 0) return 0;
    if (coinReward > maxCoinReward) return maxCoinReward;
    return coinReward;
  }

  static BattleRunSettlementResult apply({
    required bool alreadyProcessed,
    required bool won,
    required int coinReward,
    required List<String> completedNodeIds,
    required String nodeId,
    required int lives,
    bool isPvp = false,
  }) {
    if (alreadyProcessed) {
      return BattleRunSettlementResult(
        alreadyProcessed: true,
        grantCoins: 0,
        completedNodeIds: completedNodeIds,
        lives: lives,
        completedNode: false,
      );
    }
    final grant = won ? clampCoinReward(coinReward) : 0;
    final alreadyCleared = completedNodeIds.contains(nodeId);
    final nextCompleted = [
      ...completedNodeIds,
      if (won && nodeId.isNotEmpty && !alreadyCleared) nodeId,
    ];
    var nextLives = lives;
    if (!won && !isPvp) {
      nextLives = lives - 1;
      if (nextLives < 0) nextLives = 0;
    }
    return BattleRunSettlementResult(
      alreadyProcessed: false,
      grantCoins: grant,
      completedNodeIds: nextCompleted,
      lives: nextLives,
      completedNode: won && !alreadyCleared,
    );
  }
}

class BattleRunSettlementResult {
  const BattleRunSettlementResult({
    required this.alreadyProcessed,
    required this.grantCoins,
    required this.completedNodeIds,
    required this.lives,
    required this.completedNode,
  });

  final bool alreadyProcessed;
  final int grantCoins;
  final List<String> completedNodeIds;
  final int lives;
  final bool completedNode;
}

class BattleRunSubmission {
  const BattleRunSubmission({
    required this.runId,
    required this.uid,
    required this.nodeId,
    required this.heroId,
    required this.won,
    required this.coinReward,
    this.clientVersion = '0.1.4',
    this.mode = 'pve',
  });

  final String runId;
  final String uid;
  final String nodeId;
  final String heroId;
  final bool won;
  final int coinReward;
  final String clientVersion;
  final String mode;

  Map<String, dynamic> toCreatePayload() => {
        'schemaVersion': BattleRunSettlement.schemaVersion,
        'uid': uid,
        'nodeId': nodeId,
        'heroId': heroId,
        'won': won,
        'coinReward': BattleRunSettlement.clampCoinReward(coinReward),
        'clientVersion': clientVersion,
        'processed': false,
        'mode': mode,
      };
}
