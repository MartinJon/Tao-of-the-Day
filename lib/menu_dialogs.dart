// lib/menu_dialogs.dart
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'pages/subscription_page.dart';
import 'services/subscription_service.dart';
import 'services/trial_service.dart';

class _MenuDialogPalette {
  final Color primary;
  final Color background;
  final Color body;

  const _MenuDialogPalette({
    required this.primary,
    required this.background,
    required this.body,
  });

  factory _MenuDialogPalette.from(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return _MenuDialogPalette(
      primary: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
      background: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
      body: isDarkMode ? Colors.white70 : Colors.black87,
    );
  }
}

class MenuDialogs {
  static const String _fallbackAppVersion = '1.0.1+65';
  static final Future<String> _appVersionFuture = _loadAppVersion();

  // ---- Subscription helpers -------------------------------------------------

  static final SubscriptionService _subs = SubscriptionService();

  static Future<bool> _isEntitled() async {
    await _subs.initialize();               // ensure IAP ready
    return _subs.hasActiveSubscription();   // fast cached read
  }

  static Future<void> _refreshEntitlement() async {
    try {
      await _subs.initialize();
      await _subs.syncEntitlement();        // pull latest from store + cache it
    } catch (_) {
      // ignore for menu; user can still tap "Restore Purchases"
    }
  }

// (Optional, only keep if you actually call it somewhere.)
  static Future<bool> _loadEntitlementForMenu() async {
    await _subs.initialize();
    await _subs.syncEntitlement();
    return _subs.hasActiveSubscription();
  }



  // ---- Version helpers ------------------------------------------------------

  static Future<String> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final buildNumber = packageInfo.buildNumber.trim();
      return buildNumber.isNotEmpty
          ? '${packageInfo.version}+$buildNumber'
          : packageInfo.version;
    } catch (error, stackTrace) {
      debugPrint('Failed to read package info: $error');
      debugPrintStack(stackTrace: stackTrace);
      return _fallbackAppVersion;
    }
  }

  Future<String> _readAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version} (${info.buildNumber})';
  }

  Widget buildAppVersionText(BuildContext context) {
    return FutureBuilder<String>(
      future: _readAppVersion(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SizedBox.shrink();
        }
        return Text('App Version: ${snap.data}');
      },
    );
  }

  // ---- Generic helpers ------------------------------------------------------

  static List<Widget> _defaultActions(BuildContext context) {
    return [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Close'),
      ),
    ];
  }

  static Future<void> _launchExternalUrl(
      BuildContext context,
      String url,
      ) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      debugPrint('Could not launch $url');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open link: $url')),
      );
    }
  }

  // ---- Menu button ----------------------------------------------------------

  /// Call this in your AppBars: `actions: [ MenuDialogs.buildMenuButton(context) ]`
  static Widget buildMenuButton(BuildContext context) {
    // Local snapshot to avoid flicker while we refresh on open
    final ValueNotifier<bool?> entitled = ValueNotifier<bool?>(null);

    return FutureBuilder<bool>(
      // Initial entitlement check (cached)
      future: _isEntitled(),
      builder: (context, snapshot) {
        entitled.value = snapshot.data;

        return PopupMenuButton<String>(
          icon: const Icon(Icons.menu),

          // 🔄 Refresh entitlement when the menu actually opens
          onOpened: () async {
            await _refreshEntitlement();
            final fresh = await _isEntitled();
            entitled.value = fresh;
          },

          onSelected: (value) => handleMenuSelection(context, value),

          itemBuilder: (BuildContext context) {
            final items = <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'about',
                child: ListTile(
                  leading: Icon(Icons.info),
                  title: Text('About the App'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'concept',
                child: ListTile(
                  leading: Icon(Icons.lightbulb),
                  title: Text('Tao of the Day Concept'),
                ),
              ),
              // We'll insert Subscribe/Manage at index 2 below.

              const PopupMenuItem<String>(
                value: 'noomvibe',
                child: ListTile(
                  leading: Icon(Icons.live_tv),
                  title: Text('Live Show on NoomVibe'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'translation',
                child: ListTile(
                  leading: Icon(Icons.book),
                  title: Text('Get the Translation'),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'privacy',
                child: ListTile(
                  leading: Icon(Icons.privacy_tip),
                  title: Text('Privacy Policy'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'terms',
                child: ListTile(
                  leading: Icon(Icons.description),
                  title: Text('Terms of Service'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'data',
                child: ListTile(
                  leading: Icon(Icons.data_usage),
                  title: Text('Data Transparency'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'legal',
                child: ListTile(
                  leading: Icon(Icons.gavel),
                  title: Text('Legal & Disclaimers'),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'restore',
                child: ListTile(
                  leading: Icon(Icons.restore),
                  title: Text('Restore Purchases'),
                ),
              ),
            ];

            final isEntitled = entitled.value ?? false;

            // Insert either "Go Premium" or "Manage Subscription" near the top
            const insertIndex = 2;
            if (isEntitled) {
              items.insert(
                insertIndex,
                const PopupMenuItem<String>(
                  value: 'manage',
                  child: ListTile(
                    leading: Icon(Icons.star),
                    title: Text('Manage Subscription'),
                  ),
                ),
              );
            } else {
              items.insert(
                insertIndex,
                const PopupMenuItem<String>(
                  value: 'subscribe',
                  child: ListTile(
                    leading: Icon(Icons.star_border),
                    title: Text('Go Premium'),
                  ),
                ),
              );
            }

            return items;
          },
        );
      },
    );
  }

  // ---- Menu selection handler ----------------------------------------------

  static void handleMenuSelection(BuildContext context, String value) async {
    switch (value) {
      case 'about':
        showAboutDialog(context);
        break;
      case 'concept':
        showConceptDialog(context);
        break;
      case 'subscribe':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SubscriptionPage()),
        );
        break;
      case 'manage':
        _openManageSubscription();
        break;
      case 'restore':
        await _handleRestoreFlow(context);
        break;
      case 'noomvibe':
        showNoomVibeDialog(context);
        break;
      case 'translation':
        showTranslationDialog(context);
        break;
      case 'privacy':
        showPrivacyPolicyDialog(context);
        break;
      case 'terms':
        showTermsOfServiceDialog(context);
        break;
      case 'data':
        showDataTransparencyDialog(context);
        break;
      case 'legal':
        showLegalDialog(context);
        break;
    }
  }

  static Future<void> _handleRestoreFlow(BuildContext context) async {
    final scaffold = ScaffoldMessenger.of(context);
    try {
      await _subs.restorePurchases();
      await _subs.syncEntitlement();
      final ok = await _subs.hasActiveSubscription();
      scaffold.showSnackBar(
        SnackBar(
          content: Text(ok
              ? 'Purchases restored.'
              : 'No active subscription found.'),
        ),
      );
    } catch (e) {
      scaffold.showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    }
  }

  static void _openManageSubscription() {
    // Android: Play account subscriptions
    if (Platform.isAndroid) {
      launchUrl(Uri.parse('https://play.google.com/store/account/subscriptions'),
          mode: LaunchMode.externalApplication);
      return;
    }
    // iOS: Apple subscriptions management
    if (Platform.isIOS) {
      // Apple’s manage page
      launchUrl(Uri.parse('https://apps.apple.com/account/subscriptions'),
          mode: LaunchMode.externalApplication);
      return;
    }
    // Fallback (web/desktop)
    launchUrl(Uri.parse('https://play.google.com/store/account/subscriptions'),
        mode: LaunchMode.externalApplication);
  }

  // ---- Your existing dialogs (unchanged except for imports) -----------------

  static void showAboutDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          title: Text(
            'About This App',
            style: TextStyle(color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00)),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Created by MartinJon',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'This app was created to make the ancient wisdom of the Tao Te Ching accessible for daily contemplation and modern living. Each day, you can explore one of the 81 chapters and reflect on its timeless teachings.',
                  style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 16),
                Text(
                  'The daily selection limitation is intentional - I want to encourages deep reflection on a single teaching rather than superficial reading of many. I hope you take the time to explore the conversations around the chapter you selected',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'The Way of Random Selection:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your random Tao is immediately chosen for you, without option to re-roll. This practice teaches acceptance - embracing whatever chapter appears as exactly what you need to contemplate today.',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tao Journey Feature:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Track your progress through the 81 Tao chapters with the Tao Journey feature. '
                      'Toggle "Track your selections" to see which chapters you\'ve explored and focus on new ones. '
                      'Your journey is saved locally on your device.',
                  style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00)).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // Close about dialog
                      _showDeveloperMenu(context); // Show developer menu
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                        ),
                        const SizedBox(width: 8),
                        FutureBuilder<String>(
                          future: PackageInfo.fromPlatform()
                              .then((info) => '${info.version} (${info.buildNumber})'),
                          builder: (context, snap) {
                            final version = snap.data ?? '';
                            return Text(
                              version.isEmpty ? 'App Version' : 'App Version: $version',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  static void showConceptDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final headingColor = colorScheme.onSurface.withOpacity(0.87);
    final bodyColor = colorScheme.onSurface.withOpacity(0.70);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text(
            'The Tao Concept',
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Why One Tao Per Day?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: headingColor,
                  ),
                ),
                const SizedBox(height: 12),
                DefaultTextStyle.merge(
                  style: TextStyle(color: bodyColor),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('• Deep Contemplation: Focusing on one chapter allows for meaningful reflection'),
                      Text('• Practical Integration: Gives time to apply the teaching in daily life'),
                      Text('• Ancient Practice: Traditionally, Tao teachings were contemplated slowly'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'How to Use This App:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: headingColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '1. Select your Tao for the day\n2. Read the text slowly\n3. Listen to the discussions\n4. Reflect throughout the day\n5. Return tomorrow for new wisdom',
                  style: TextStyle(color: bodyColor),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: TextStyle(color: colorScheme.primary)),
            ),
          ],
        );
      },
    );
  }

  static void showNoomVibeDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          title: Text(
            'Live Tao of the Day Show',
            style: TextStyle(color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00)),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Join me live on NoomVibe!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Experience the Tao of the Day through live discussions and community conversations. Click the link below to find me on the NoomVibe app where I host live Tao of the Day shows at 6am Central time Mon through Friday',
                  style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 12),
                Text(
                  'Platform: NoomVibe',
                  style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                ),
                Text(
                  'Schedule: M-F 6a Central',
                  style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final Uri uri = Uri.parse("https://noomvibe.app/martinjon");
                    if (!await launchUrl(uri)) {
                      throw Exception('Could not launch URL');
                    }
                  },
                  child: Text(
                    '👉 Tap here to visit NoomVibe',
                    style: TextStyle(
                      color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  static void showTranslationDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          title: Text(
            'Get the Complete Translation',
            style: TextStyle(color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00)),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Deepen Your Practice',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Get the printed version of my translation of the Tao te Ching.',
                  style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final Uri uri = Uri.parse("https://www.martinjon.com/product-page/tao-te-ching");
                    if (!await launchUrl(uri)) {
                      throw Exception('Could not launch URL');
                    }
                  },
                  child: Text(
                    '📚 Available in Paperback',
                    style: TextStyle(
                      color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  static void showPrivacyPolicyDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          title: Text(
            'Privacy Policy',
            style: TextStyle(color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00)),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Last Updated: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final Uri uri = Uri.parse("https://www.martinjon.com/tao-app-privacy");
                    if (!await launchUrl(uri)) {
                      throw Exception('Could not launch URL');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00)).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.launch, size: 16, color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'View Full Privacy Policy Online',
                            style: TextStyle(
                              color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Data Collection & Usage',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Daily Selection: We store your daily Tao selection locally on your device to enforce the "one Tao per day" feature\n'
                      '• App Preferences: Theme preferences and settings are stored locally\n'
                      '• No Personal Data: We do not collect, store, or transmit any personally identifiable information\n'
                      '• No Analytics: We do not use analytics or tracking services\n'
                      '• No Third-Party Sharing: We do not share any data with third parties',
                  style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 16),
                Text(
                  'Local Storage',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This app uses local storage (SharedPreferences) to remember:\n'
                      '• Your selected Tao number for the current day\n'
                      '• The date of your last selection\n'
                      '• Your theme preference (light/dark mode)',
                  style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 16),
                Text(
                  'External Links',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This app contains links to external websites (NoomVibe, MartinJon.com). '
                      'We are not responsible for the privacy practices of these external sites.',
                  style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 16),
                Text(
                  'Contact',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'For privacy-related questions, contact: MartinJon@martinjon.com',
                  style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  static void showTermsOfServiceDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          title: Text(
            'Terms of Service',
            style: TextStyle(color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00)),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Acceptance of Terms',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'By using Tao of the Day, you agree to these terms and conditions.',
                  style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 16),
                Text(
                  'Educational Purpose',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This app is provided for educational and contemplative purposes only. '
                      'The content is not intended as professional advice, medical guidance, or psychological counseling.',
                  style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 16),
                Text(
                  'Intellectual Property',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Tao Te Ching text: Based on ancient public domain works with modern interpretation\n'
                      '• Audio content: Original discussions created by MartinJon\n'
                      '• App design and code: Copyright © ${DateTime.now().year} MartinJon\n'
                      '• All rights reserved for original content and app implementation',
                  style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 16),
                Text(
                  'User Responsibilities',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Use the app as intended for personal contemplation\n'
                      '• Respect the daily limitation feature\n'
                      '• Do not attempt to reverse engineer or modify the app\n'
                      '• Use audio content for personal educational purposes only',
                  style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 16),
                Text(
                  'Limitation of Liability',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  'The creators are not responsible for individual interpretations or applications of the Tao teachings. '
                      'Users apply the wisdom at their own discretion and responsibility.',
                  style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 16),
                Text(
                  'Changes to Terms',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  'We reserve the right to modify these terms at any time. Continued use of the app constitutes acceptance of updated terms.',
                  style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  static void showDataTransparencyDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          title: Text(
            'Data Transparency',
            style: TextStyle(color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00)),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'We believe in complete transparency about what data we handle:',
                  style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00)).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📱 Data We Store Locally:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• selectedNumber: Your daily Tao choice (e.g., "42")\n'
                            '• selectedNumberDate: Date of selection (e.g., "20241225")\n'
                            '• selectedNumbers: Your Tao journey progress (e.g., "[1, 5, 42]")\n'
                            '• filterUsedNumbers: Tao journey filter preference\n'
                            '• Theme preference: Your light/dark mode choice',
                        style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '✅ Data We NEVER Collect:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Personal identification information\n'
                            '• Email addresses or contact details\n'
                            '• Location data or device identifiers\n'
                            '• Usage analytics or behavior tracking\n'
                            '• Payment or financial information',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'External Data Sources:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Tao content: Loaded from a bundled JSON file on your device\n'
                      '• Audio files: Streamed from external hosting services\n'
                      '• No analytics or tracking',
                  style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your Privacy Matters',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This app is designed to respect your privacy completely. '
                      'We minimize data collection to only what\'s necessary for core functionality.',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  static void showLegalDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          title: Text(
            'Legal & Disclaimers',
            style: TextStyle(color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00)),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Educational Purpose Only',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'This app is for educational and contemplative purposes only. The content is not intended as professional advice, medical guidance, or psychological counseling.',
                  style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tao Te Ching Text:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The Tao Te Ching text used in this app is based on ancient public domain works with modern interpretation. Various translations and commentaries have been referenced to create this work. I do not read ancient Chinese.',
                  style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 16),
                Text(
                  'Personal Responsibility:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Users are encouraged to apply the teachings with wisdom and discretion in their personal lives. The creators are not responsible for individual interpretations or applications of the material.',
                  style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 16),
                Text(
                  'Contact:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'For questions or concerns, please contact MartinJon@martinjon.com',
                  style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ---- Developer menu -------------------------------------------------------

  static void _showDeveloperMenu(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Developer Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.delete, color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00)),
              title: const Text('Reset Trial'),
              onTap: () {
                TrialService.resetTrial();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Trial reset')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.visibility, color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00)),
              title: const Text('Check Subscription Status'),
              onTap: () async {
                Navigator.pop(context);
                _checkSubscriptionStatus(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.shopping_cart, color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00)),
              title: const Text('Force Subscription Page'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SubscriptionPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static void _checkSubscriptionStatus(BuildContext context) async {
    await _subs.initialize();
    final hasAccess = await _subs.hasActiveSubscription();
    final isSubscribed = await _subs.hasActiveSubscription();
    final inTrial = await TrialService.isTrialActive();
    final daysRemaining = await TrialService.getDaysRemaining();

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Subscription Status', style: TextStyle(color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Has Access: $hasAccess'),
            Text('Is Subscribed: $isSubscribed'),
            Text('In Trial: $inTrial'),
            Text('Days Remaining: $daysRemaining'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
