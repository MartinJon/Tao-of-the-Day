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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if user has already selected a Tao for today
  final prefs = await SharedPreferences.getInstance();
  final currentDate = DateFormat('yyyyMMdd').format(DateTime.now());
  final lastSelectedDate = prefs.getString('selectedNumberDate') ?? '';
  final lastSelectedNumber = prefs.getInt('selectedNumber') ?? 0;

  // If user has selected a Tao today, load the data first
  if (lastSelectedDate == currentDate && lastSelectedNumber > 0) {
    await _loadTaoDataAndLaunchApp(lastSelectedNumber);
  } else {
    runApp(MyApp());
  }
}


// Helper function to load Tao data and launch app directly to detail page
Future<void> _loadTaoDataAndLaunchApp(int taoNumber) async {
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
      runApp(MyApp(initialRoute: taoData));
    } else {
      // Fallback to normal launch
      runApp(MyApp());
    }
  } catch (e) {
    print('❌ Error in _loadTaoDataAndLaunchApp: $e');
    // Fallback to normal launch on error
    runApp(MyApp());
  }
}

class MyApp extends StatelessWidget {
  final TaoData? initialRoute;

  const MyApp({super.key, this.initialRoute});

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
      home: initialRoute != null
          ? TaoDetailPage(taoData: initialRoute!)
          : const NumberSelectorPage(),
    );
  }

}
