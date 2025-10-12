import 'package:flutter/material.dart';
import 'package:tao_app_fixed_clean/services/storage_service.dart';

class WelcomeWrapper extends StatefulWidget {
  final Widget child;

  const WelcomeWrapper({super.key, required this.child});

  @override
  _WelcomeWrapperState createState() => _WelcomeWrapperState();
}

class _WelcomeWrapperState extends State<WelcomeWrapper> {
  @override
  void initState() {
    super.initState();
    // Show welcome dialog after a brief delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeDialog();
    });
  }

  void _showWelcomeDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to close
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          title: Text(
            'Welcome to\nTao of the Day',
            style: TextStyle(
              color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 50,
                  color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tao of the Day invites you to explore one of the 81 chapters of the Tao Te Ching each day, either by direct selection or through random chance.',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'This daily practice of receiving just one chapter—rather than browsing many—cultivates the art of surrender and deep contemplation. Each selection becomes your personal oracle for the day.',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Embrace what appears as exactly what you need to contemplate today.',
                  style: TextStyle(
                    color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Mark as seen and close
                  StorageService.setWelcomeShown();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Begin My Tao Journey'),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}