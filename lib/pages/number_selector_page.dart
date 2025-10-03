// pages/number_selector_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/tao_data.dart';
import '../menu_dialogs.dart';
import '../pages/tao_detail_page.dart';
import '../services/tao_service.dart';
import '../services/storage_service.dart';
import 'dart:math';

class NumberSelectorPage extends StatefulWidget {
  const NumberSelectorPage({super.key});

  @override
  _NumberSelectorPageState createState() => _NumberSelectorPageState();
}

class _NumberSelectorPageState extends State<NumberSelectorPage> {
  int _selectedNumber = 1;
  List<TaoData> _taoDataList = [];
  bool _isButtonEnabled = true;
  bool _isLoading = false;
  bool _hasError = false;
  List<int> _selectedNumbers = [];
  bool _filterUsedNumbers = false;

  // === STORAGE METHODS ===
  Future<void> _loadSelectedNumbers() async {
    _selectedNumbers = await StorageService.loadSelectedNumbers();
    _filterUsedNumbers = await StorageService.getFilterUsedNumbers();
  }

  Future<void> _toggleFilterUsedNumbers(bool value) async {
    await StorageService.setFilterUsedNumbers(value);
    setState(() {
      _filterUsedNumbers = value;
    });
  }

  Future<bool> _canSelectNewNumber() async {
    return await StorageService.canSelectNewNumber();
  }

  void _resetTaoJourney() async {
    await StorageService.resetTaoJourney();
    setState(() {
      _selectedNumbers.clear();
      _filterUsedNumbers = false;
    });
  }
  // === END STORAGE METHODS ===

  Future<void> _fetchTaoDataWithRetry({int retries = 3}) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    for (int attempt = 1; attempt <= retries; attempt++) {
      try {
        print('🔄 Attempt $attempt of $retries to fetch data...');
        await _fetchTaoData();
        return; // Success - exit the retry loop
      } catch (e) {
        print('❌ Attempt $attempt failed: $e');
        if (attempt == retries) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
          _showNetworkErrorDialog();
        } else {
          print('⏳ Waiting ${attempt * 2} seconds before retry...');
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }
  }

  Future<void> _fetchTaoData() async {
    try {
      print('📦 Loading local Tao data from JSON...');
      await _loadLocalTaoData();
    } catch (e) {
      print('❌ Error loading local data: $e');
      _showFallbackData();
    }
  }

  Future<void> _loadLocalTaoData() async {
    try {
      final taoDataList = await TaoService.loadLocalTaoData();
      setState(() {
        _taoDataList = taoDataList;
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      print('❌ Error loading local data: $e');
      _showFallbackData();
    }
  }

  void _showFallbackData() {
    setState(() {
      _taoDataList = TaoService.getFallbackData();
      _isLoading = false;
      _hasError = false;
    });
  }

  void _showNetworkErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          title: Text(
              'Connection Issue',
              style: TextStyle(color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00))
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                  Icons.wifi_off,
                  size: 50,
                  color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00)
              ),
              SizedBox(height: 16),
              Text(
                "Can't connect to Tao data. This could be due to:\n\n"
                    "• Network connectivity issues\n"
                    "• Firewall blocking the connection\n"
                    "• Temporary server problems\n\n"
                    "The app will use sample data instead.",
                textAlign: TextAlign.left,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _fetchTaoDataWithRetry();
              },
              child: Text('Retry'),
            ),
          ],
        );
      },
    );
  }

  void _selectRandomNumber() {
    // Get available numbers based on filter setting
    List<int> availableNumbers;

    if (_filterUsedNumbers && _selectedNumbers.isNotEmpty) {
      // Only show numbers that haven't been selected
      availableNumbers = List.generate(81, (index) => index + 1)
          .where((number) => !_selectedNumbers.contains(number))
          .toList();

      // If all numbers have been selected, show a message
      if (availableNumbers.isEmpty) {
        _showAllTaoCompletedDialog();
        return;
      }
    } else {
      // Show all numbers (original behavior)
      availableNumbers = _taoDataList.map((tao) => tao.number).toList();
    }

    if (availableNumbers.isNotEmpty) {
      final random = Random();
      final randomNumber = availableNumbers[random.nextInt(availableNumbers.length)];

      setState(() {
        _selectedNumber = randomNumber;
      });

      // Immediately navigate to the Tao detail page
      _navigateToTaoDetail(randomNumber);
    }
  }

  void _showAllTaoCompletedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          title: Text(
              'Tao Journey Complete! 🎉',
              style: TextStyle(color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00))
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                  Icons.celebration,
                  size: 50,
                  color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00)
              ),
              SizedBox(height: 16),
              Text(
                'You have explored all 81 Tao chapters! '
                    'This is a significant milestone in your Tao journey.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToTaoDetail(int number) async {
    final canSelectNew = await _canSelectNewNumber();

    // DAILY LIMIT CHECK
    if (!canSelectNew) {
      final lastSelected = await StorageService.getLastSelectedNumber();
      if (number != lastSelected) {
        _showAlreadySelectedDialog();
        return;
      }
    }

    final taoData = _taoDataList.firstWhere(
          (data) => data.number == number,
      orElse: () => TaoData.empty(),
    );

    if (taoData.number != 0) {
      // SAVE LOGIC - Only if it's a new daily selection
      if (canSelectNew) {
        await StorageService.saveDailySelection(number);
        await StorageService.saveSelectedNumber(number);
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TaoDetailPage(taoData: taoData),
        ),
      );
    } else {
      _showErrorDialog('No data found for Tao $number.', isRetryable: false);
    }

    print('🔍 DAILY LIMIT DEBUG: canSelectNew = $canSelectNew');
    print('🔍 DAILY LIMIT DEBUG: number = $number');
  }

  void _showAlreadySelectedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Daily Tao Already Selected'),
          content: const Text('You can only explore one Tao number per day. Please come back tomorrow to explore another.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message, {bool isRetryable = false}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            if (isRetryable) TextButton(
              onPressed: () {
                Navigator.pop(context);
                _fetchTaoDataWithRetry();
              },
              child: const Text('Retry'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchTaoDataWithRetry();
    _checkDailySelection();
    _loadSelectedNumbers();
  }

  Future<void> _checkDailySelection() async {
    final canSelectNew = await _canSelectNewNumber();
    setState(() {
      _isButtonEnabled = canSelectNew;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tao of the Day'),
        backgroundColor: isDarkMode ? const Color(0xFF5C1A00) : const Color(0xFF7E1A00),
        actions: [
          MenuDialogs.buildMenuButton(context),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _buildMainContent(isDarkMode),
      ),
    );
  }

  Widget _buildMainContent(bool isDarkMode) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
            ),
            const SizedBox(height: 20),
            const Text('Loading Tao data...'),
            if (_hasError) ...[
              const SizedBox(height: 10),
              Text(
                'Having trouble connecting...',
                style: TextStyle(
                  color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Select a Tao Chapter (1-81):',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Number selector with Tao Journey indicators
          Builder(
            builder: (context) {
              return Container(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: List.generate(81, (index) {
                    final number = index + 1;
                    final isSelected = _selectedNumber == number;
                    final isInJourney = _selectedNumbers.contains(number);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedNumber = number;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        child: Stack(
                          children: [
                            Text(
                              '$number',
                              style: TextStyle(
                                fontSize: isSelected ? 40 : 24,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected
                                    ? (isDarkMode ? const Color(0xFFFFD26F) : const Color(0xFF7E1A00))
                                    : (isDarkMode ? const Color(0xFFD45C33) : const Color(0xFFD45C33)),
                              ),
                            ),
                            if (isInJourney && _filterUsedNumbers)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              );
            },
          ),

          const SizedBox(height: 50),

          Text(
            'Swipe horizontally',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
              fontSize: 15,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),

          Wrap(
            alignment: WrapAlignment.spaceEvenly,
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: _isButtonEnabled ? () => _selectRandomNumber() : null,
                icon: const Icon(Icons.shuffle),
                label: const Text('Random Tao'),
              ),
              ElevatedButton.icon(
                onPressed: (_isButtonEnabled && !_isLoading) ? () => _navigateToTaoDetail(_selectedNumber) : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Explore Tao'),
              ),
            ],
          ),

          if (!_isButtonEnabled) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFFFD26F)).withOpacity(0.8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00)),
              ),
              child: Text(
                'You have already selected your Tao for today.\nCome back tomorrow to explore another.',
                textAlign: TextAlign.center,
                style: TextStyle(color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00)),
              ),
            ),
          ],

          Container(
            padding: const EdgeInsets.only(top: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 20,
                      color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Previous selections',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 8),
                    Switch(
                      value: _filterUsedNumbers,
                      onChanged: _toggleFilterUsedNumbers,
                      activeColor: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                    ),
                  ],
                ),

                if (_filterUsedNumbers) ...[
                  SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Tao Journey: ${_selectedNumbers.length}/81 explored',
                      style: TextStyle(
                        color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (_selectedNumbers.isNotEmpty)
                    TextButton(
                      onPressed: _resetTaoJourney,
                      child: Text(
                        'Reset Journey',
                        style: TextStyle(
                          color: isDarkMode ? Colors.red : Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}