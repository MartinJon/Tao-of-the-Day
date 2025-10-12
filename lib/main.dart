//cd "C:\Users\MartinJon\AndroidStudioProjects\tao_of_the_day_app"
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/tao_data.dart';
import 'pages/number_selector_page.dart';
import 'pages/tao_detail_page.dart';
import 'menu_dialogs.dart';
import 'audio_player.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'welcome_wrapper.dart';
import 'package:tao_app_fixed_clean/services/storage_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🔍 Testing StorageService import...');
  try {
    final test = await StorageService.shouldShowWelcome();
    print('✅ StorageService test passed: $test');
  } catch (e) {
    print('❌ StorageService test failed: $e');
  }

  // Check if we should show welcome dialog
  final bool shouldShowWelcome = await StorageService.shouldShowWelcome();

  // Check if user has already selected a Tao for today
  final prefs = await SharedPreferences.getInstance();
  final currentDate = DateFormat('yyyyMMdd').format(DateTime.now());
  final lastSelectedDate = prefs.getString('selectedNumberDate') ?? '';
  final lastSelectedNumber = prefs.getInt('selectedNumber') ?? 0;

  // If user has selected a Tao today, load the data first
  if (lastSelectedDate == currentDate && lastSelectedNumber > 0) {
    await _loadTaoDataAndLaunchApp(lastSelectedNumber, shouldShowWelcome);
  } else {
    runApp(MyApp(shouldShowWelcome: shouldShowWelcome));
  }
}


// Helper function to load Tao data and launch app directly to detail page
Future<void> _loadTaoDataAndLaunchApp(int taoNumber, bool shouldShowWelcome) async {
  try {
    print('📦 Loading local Tao data for direct launch...');

    // Load from local JSON
    final String data = await rootBundle.loadString('lib/data/tao_data.json');
    final List<dynamic> jsonList = jsonDecode(data);

    final List<TaoData> taoDataList = [];

    for (final json in jsonList) {
      try {
        final taoData = TaoData.fromJson(json);
        if (taoData.number > 0) {
          taoDataList.add(taoData);
        }
      } catch (e) {
        print('❌ Error parsing Tao entry: $e');
        // Continue with other entries instead of failing completely
      }
    }

    if (taoDataList.isEmpty) {
      throw Exception('No valid Tao data found');
    }

    taoDataList.sort((a, b) => a.number.compareTo(b.number));

    // Find the Tao data for the selected number
    final taoData = taoDataList.firstWhere(
          (data) => data.number == taoNumber,
      orElse: () => TaoData.empty(),
    );

    if (taoData.number != 0) {
      // Launch app directly to the detail page
      runApp(MyApp(initialRoute: taoData, shouldShowWelcome: shouldShowWelcome));
    } else {
      // Fallback to normal launch
      runApp(MyApp(shouldShowWelcome: shouldShowWelcome));
    }
  } catch (e) {
    print('❌ Error in _loadTaoDataAndLaunchApp: $e');
    // Fallback to normal launch on error
    runApp(MyApp(shouldShowWelcome: shouldShowWelcome));
  }
}

class MyApp extends StatelessWidget {
  final TaoData? initialRoute;
  final bool shouldShowWelcome;

  const MyApp({super.key, this.initialRoute, this.shouldShowWelcome = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tao of the Day',
      theme: ThemeData(
        primaryColor: const Color(0xFFAB3300),
        scaffoldBackgroundColor: const Color(0xFFFFD26F),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF7E1A00),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: TextTheme(
          headlineSmall: TextStyle(
            color: const Color(0xFF7E1A00),
            fontWeight: FontWeight.bold,
          ),
          bodyMedium: TextStyle(
            color: Colors.black,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7E1A00),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primaryColor: const Color(0xFFD45C33),
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF5C1A00),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: TextTheme(
          headlineSmall: TextStyle(
            color: const Color(0xFFD45C33),
            fontWeight: FontWeight.bold,
          ),
          bodyMedium: TextStyle(
            color: Colors.white70,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5C1A00),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: shouldShowWelcome
          ? (initialRoute != null
          ? TaoDetailPage(taoData: initialRoute!)
          : const NumberSelectorPage())
          : WelcomeWrapper(
        child: initialRoute != null
            ? TaoDetailPage(taoData: initialRoute!)
            : const NumberSelectorPage(),
      ),
    );
  }

}
