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

  static Future<bool> shouldShowWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('welcomeShown') ?? false;
  }

  static Future<void> setWelcomeShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('welcomeShown', true);
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

  static Future<bool> canSelectNewNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSelectedDate = prefs.getString('selectedNumberDate') ?? '';

    // Simple device time check
    final currentDeviceDate = DateFormat('yyyyMMdd').format(DateTime.now());

    print('📅 DATE CHECK: Last selected: $lastSelectedDate, Current device: $currentDeviceDate');

    return lastSelectedDate != currentDeviceDate;
  }

  static Future<void> saveDailySelection(int number) async {
    final prefs = await SharedPreferences.getInstance();

    // Use simple device time
    final currentDeviceDate = DateFormat('yyyyMMdd').format(DateTime.now());

    await prefs.setInt('selectedNumber', number);
    await prefs.setString('selectedNumberDate', currentDeviceDate);

    print('💾 Saved Tao $number for date: $currentDeviceDate');
  }

  static Future<int> getLastSelectedNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('selectedNumber') ?? 0;
  }
 }