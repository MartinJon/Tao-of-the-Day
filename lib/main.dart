//cd "C:\Users\MartinJon\AndroidStudioProjects\tao_of_the_day_app"
// lib/main.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'models/tao_data.dart';
import 'pages/number_selector_page.dart';
import 'pages/tao_detail_page.dart';
import 'menu_dialogs.dart';
import 'welcome_wrapper.dart';
import 'services/storage_service.dart';
import 'services/tao_service.dart';
import 'widgets/universal_audio_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bool hasSeenWelcome = await StorageService.shouldShowWelcome();

  // If first time user, show welcome flow
  if (!hasSeenWelcome) {
    runApp(const MyApp(showWelcome: true));
    return;
  }

  // Returning user - check if they have today's Tao selected
  final prefs = await SharedPreferences.getInstance();
  final currentDate = DateFormat('yyyyMMdd').format(DateTime.now());
  final lastSelectedDate = prefs.getString('selectedNumberDate') ?? '';
  final lastSelectedNumber = prefs.getInt('selectedNumber') ?? 0;

  // If user has today's Tao selected, go directly to it
  if (lastSelectedDate == currentDate && lastSelectedNumber > 0) {
    await _launchToTaoDetail(lastSelectedNumber);
  } else {
    // Go to selector page
    runApp(const MyApp(showWelcome: false));
  }
}

// Simplified helper to launch directly to Tao detail
Future<void> _launchToTaoDetail(int taoNumber) async {
  try {
    final taoDataList = await TaoService.loadLocalTaoData();
    final taoData = taoDataList.firstWhere(
          (data) => data.number == taoNumber,
      orElse: () => TaoData.empty(),
    );

    if (taoData.number != 0) {
      runApp(MyApp(showWelcome: false, initialTao: taoData));
    } else {
      runApp(const MyApp(showWelcome: false));
    }
  } catch (e) {
    print('❌ Error launching to Tao detail: $e');
    runApp(const MyApp(showWelcome: false));
  }
}
class MyApp extends StatelessWidget {
  final bool showWelcome;
  final TaoData? initialTao;

  const MyApp({
    super.key,
    required this.showWelcome,
    this.initialTao
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AudioService(),
      child: MaterialApp(
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
        home: showWelcome
            ? WelcomeWrapper(
          child: initialTao != null
              ? TaoDetailPage(taoData: initialTao!)
              : const NumberSelectorPage(),
        )
            : (initialTao != null
            ? TaoDetailPage(taoData: initialTao!)
            : const NumberSelectorPage()),
      ),
    );
  }
}