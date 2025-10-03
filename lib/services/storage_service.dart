// services/storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class StorageService {
  // Tao Journey methods
  static Future<void> resetTaoJourney() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selectedNumbers');
  }

  static Future<List<int>> loadSelectedNumbers() async {
    final prefs = await SharedPreferences.getInstance();
    final selected = prefs.getStringList('selectedNumbers') ?? [];
    return selected.map((e) => int.parse(e)).toList();
  }

  static Future<void> saveSelectedNumber(int number) async {
    final prefs = await SharedPreferences.getInstance();
    final currentNumbers = await loadSelectedNumbers();

    if (!currentNumbers.contains(number)) {
      currentNumbers.add(number);
      await prefs.setStringList(
          'selectedNumbers',
          currentNumbers.map((e) => e.toString()).toList()
      );
    }
  }

  static Future<bool> getFilterUsedNumbers() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('filterUsedNumbers') ?? false;
  }

  static Future<void> setFilterUsedNumbers(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('filterUsedNumbers', value);
  }

  // Daily selection methods
  static Future<bool> canSelectNewNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final currentDate = DateFormat('yyyyMMdd').format(DateTime.now());
    final lastSelectedDate = prefs.getString('selectedNumberDate') ?? '';
    return lastSelectedDate != currentDate;
  }

  static Future<void> saveDailySelection(int number) async {
    final prefs = await SharedPreferences.getInstance();
    final currentDate = DateFormat('yyyyMMdd').format(DateTime.now());

    await prefs.setInt('selectedNumber', number);
    await prefs.setString('selectedNumberDate', currentDate);
  }

  static Future<int> getLastSelectedNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('selectedNumber') ?? 0;
  }
}