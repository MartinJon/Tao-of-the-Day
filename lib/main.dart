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
import 'services/subscription_service.dart';
import 'services/shared_prefrences.dart';
import 'pages/subscription_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize subscription service first - FIXED
  await SubscriptionService.ensureInitialized();

  // 2. Start trial if this is user's first time
  await TrialService.startTrialIfNeeded();

  // 3. CHECK SUBSCRIPTION ACCESS - THIS IS THE GATEKEEPER
  final bool canAccessApp = await _checkAppAccess();

  if (!canAccessApp) {
    // USER CANNOT ACCESS APP - show subscription page immediately
    print('🚫 User cannot access app - showing subscription page');
    runApp(const MyApp(
      showWelcome: false, // Required parameter
      showSubscriptionRequired: true,
    ));
    return;
  }

  // USER CAN ACCESS APP - continue with normal app flow
  print('✅ User can access app - showing normal content');

  // Existing welcome flow for users with access
  final bool hasSeenWelcome = await StorageService.shouldShowWelcome();

  if (!hasSeenWelcome) {
    runApp(const MyApp(showWelcome: true));
    return;
  }

  // Returning user - check if they have today's Tao selected
  final prefs = await SharedPreferences.getInstance();
  final currentDate = DateFormat('yyyyMMdd').format(DateTime.now());
  final lastSelectedDate = prefs.getString('selectedNumberDate') ?? '';
  final lastSelectedNumber = prefs.getInt('selectedNumber') ?? 0;

  if (lastSelectedDate == currentDate && lastSelectedNumber > 0) {
    await _launchToTaoDetail(lastSelectedNumber);
  } else {
    runApp(const MyApp(showWelcome: false));
  }
}

// NEW FUNCTION: The gatekeeper that decides if user can use the app
Future<bool> _checkAppAccess() async {
  // Check if user has active subscription (paid user)
  final hasActiveSubscription = await SubscriptionService().hasActiveSubscription();
  if (hasActiveSubscription) {
    print('💰 User has active subscription');
    return true;
  }

  // Check if user is in trial period (new user)
  final trialActive = await TrialService.isTrialActive();
  if (trialActive) {
    print('🆓 User is in trial period');
    return true;
  }

  // User has no subscription and trial expired - NO ACCESS
  print('❌ User has no subscription and trial expired');
  return false;
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
  final bool showSubscriptionRequired;

  const MyApp({
    super.key,
    required this.showWelcome,
    this.initialTao,
    this.showSubscriptionRequired = false,
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
        home: _buildHome(),
      ),
    );
  }

  Widget _buildHome() {
    if (showSubscriptionRequired) {
      return const SubscriptionPage();
    }

    if (showWelcome) {
      return WelcomeWrapper(
        child: initialTao != null
            ? TaoDetailPage(taoData: initialTao!)
            : const NumberSelectorPage(),
      );
    }

    return initialTao != null
        ? TaoDetailPage(taoData: initialTao!)
        : const NumberSelectorPage();
  }
}