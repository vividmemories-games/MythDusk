import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_flavor.dart';

/// Local rewarded-ad stub plus a daily cap. No ad-network SDK until store
/// and consent are wired (Monetization Phase 3).
class RewardedAdService {
  const RewardedAdService();

  static const prefsDayKey = 'mythdusk_ad_day';
  static const prefsCountKey = 'mythdusk_ad_count';
  static const defaultDailyCap = 5;

  bool get isAvailable => AppFlavor.showQaTools;

  bool canShow(
    SharedPreferences prefs, {
    int cap = defaultDailyCap,
    DateTime? now,
  }) {
    if (!isAvailable) return false;
    return usedToday(prefs, now: now) < cap;
  }

  int usedToday(SharedPreferences prefs, {DateTime? now}) {
    final day = _dayKey(now ?? DateTime.now().toUtc());
    if (prefs.getString(prefsDayKey) != day) return 0;
    return prefs.getInt(prefsCountKey) ?? 0;
  }

  Future<bool> showRewardedAd({
    required String reasonKey,
    SharedPreferences? prefs,
    int cap = defaultDailyCap,
  }) async {
    if (!isAvailable) return false;
    if (prefs != null && !canShow(prefs, cap: cap)) return false;
    if (prefs != null) {
      await record(prefs);
    }
    return true;
  }

  Future<void> record(SharedPreferences prefs, {DateTime? now}) async {
    final day = _dayKey(now ?? DateTime.now().toUtc());
    final count = prefs.getString(prefsDayKey) == day
        ? (prefs.getInt(prefsCountKey) ?? 0)
        : 0;
    await prefs.setString(prefsDayKey, day);
    await prefs.setInt(prefsCountKey, count + 1);
  }

  static String _dayKey(DateTime now) =>
      '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}
