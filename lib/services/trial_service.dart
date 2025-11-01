// services/trial_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class TrialService {
  static const String _trialStartKey = 'trial_start_date';
  static const int _trialDays = 3;

  // Call this when user first opens the app
  static Future<void> startTrialIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final trialStartString = prefs.getString(_trialStartKey);

    // If no trial start date, this is their first time - start trial!
    if (trialStartString == null) {
      final now = DateTime.now();
      await prefs.setString(_trialStartKey, now.toIso8601String());
      print('🎉 Trial started: $now');
    }
  }

  // Check if user is still in their 3-day trial period
  static Future<bool> isTrialActive() async {
    final prefs = await SharedPreferences.getInstance();
    final trialStartString = prefs.getString(_trialStartKey);

    // If no trial date, they haven't started - so yes, trial is "active" (they can start it)
    if (trialStartString == null) {
      return true;
    }

    final trialStart = DateTime.parse(trialStartString);
    final trialEnd = trialStart.add(Duration(days: _trialDays));
    final now = DateTime.now();

    return now.isBefore(trialEnd);
  }

  // How many days left in trial (for display)
  static Future<int> getDaysRemaining() async {
    final prefs = await SharedPreferences.getInstance();
    final trialStartString = prefs.getString(_trialStartKey);

    if (trialStartString == null) {
      return _trialDays; // Full trial remaining
    }

    final trialStart = DateTime.parse(trialStartString);
    final trialEnd = trialStart.add(Duration(days: _trialDays));
    final now = DateTime.now();

    if (now.isAfter(trialEnd)) {
      return 0; // Trial expired
    }

    return trialEnd.difference(now).inDays;
  }

  // For testing only - reset the trial
  static Future<void> resetTrial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_trialStartKey);
    print('🔄 Trial reset');
  }
}