// services/storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  // Network time method
  static Future<DateTime> getNetworkTime() async {
    try {
      final response = await http.get(Uri.parse('http://worldtimeapi.org/api/ip'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final datetimeString = data['datetime'];
        return DateTime.parse(datetimeString);
      }
    } catch (e) {
      print('❌ Network time failed: $e');
    }

    // Fallback to device time if network fails
    print('⚠️ Using device time as fallback');
    return DateTime.now();
  }

  // Updated daily selection method with network time check
  static Future<bool> canSelectNewNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSelectedDate = prefs.getString('selectedNumberDate') ?? '';

    // Use network time instead of device time
    final currentNetworkDate = DateFormat('yyyyMMdd').format(await getNetworkTime());

    print('🔍 DATE CHECK: Last selected: $lastSelectedDate, Current network: $currentNetworkDate');

    return lastSelectedDate != currentNetworkDate;
  }

  static Future<void> saveDailySelection(int number) async {
    final prefs = await SharedPreferences.getInstance();

    // Use network time for consistency
    final currentNetworkDate = DateFormat('yyyyMMdd').format(await getNetworkTime());

    await prefs.setInt('selectedNumber', number);
    await prefs.setString('selectedNumberDate', currentNetworkDate);

    print('💾 Saved Tao $number for date: $currentNetworkDate');
  }

  static Future<int> getLastSelectedNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('selectedNumber') ?? 0;
  }
}