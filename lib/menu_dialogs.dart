import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MenuDialogs {
  static const String appVersion = '1.0.0';
  // Menu button widget
  static PopupMenuButton<String> buildMenuButton(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.menu),
      onSelected: (value) => handleMenuSelection(context, value),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
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
      ],
    );
  }

  // Menu selection handler
  static void handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'about':
        showAboutDialog(context);
        break;
      case 'concept':
        showConceptDialog(context);
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'App Version: $appVersion', // ← Simple static version
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                        ),
                      ),
                    ],
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          title: Text(
            'The Tao Concept',
            style: TextStyle(color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00)),
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
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '• Deep Contemplation: Focusing on one chapter allows for meaningful reflection',
                  style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                ),
                Text(
                  '• Practical Integration: Gives time to apply the teaching in daily life',
                  style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                ),
                Text(
                  '• Ancient Practice: Traditionally, Tao teachings were contemplated slowly',
                  style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 16),
                Text(
                  'How to Use This App:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '1. Select your Tao for the day\n2. Read the text slowly\n3. Listen to the discussions\n4. Reflect throughout the day\n5. Return tomorrow for new wisdom',
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
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
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
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
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
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
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
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
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
                    children: [
                      Text(
                        '✅ Data We NEVER Collect:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Personal identification information\n'
                            '• Email addresses or contact details\n'
                            '• Location data or device identifiers\n'
                            '• Usage analytics or behavior tracking\n'
                            '• Payment or financial information',
                        style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
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
                  '• Tao content: Loaded from Google Sheets (public CSV)\n'
                      '• Audio files: Streamed from external hosting services\n'
                      '• All external data is loaded in real-time, not stored permanently',
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

  // Helper method for launching URLs
  //static Future<void> launchExternalUrl(String url) async {
    //final Uri uri = Uri.parse(url);
    //if (!await launchUrl(uri)) {
      //throw Exception('Could not launch $url');
    //}
  //}
}