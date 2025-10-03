//cd "C:\Users\MartinJon\AndroidStudioProjects\tao_of_the_day_app"
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
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
      final taoData = TaoData.fromJson(json);  // Use fromJson
      if (taoData.number > 0) {
        taoDataList.add(taoData);
      }
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

  Future<void> _resetTaoJourney() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selectedNumbers');
    setState(() {
      _selectedNumbers.clear();
      _filterUsedNumbers = false;
    });
  }

  Future<void> _loadSelectedNumbers() async {
    final prefs = await SharedPreferences.getInstance();
    final selected = prefs.getStringList('selectedNumbers') ?? [];
    _selectedNumbers = selected.map((e) => int.parse(e)).toList();

    // Load the filter preference
    _filterUsedNumbers = prefs.getBool('filterUsedNumbers') ?? false;
  }

  Future<void> _saveSelectedNumber(int number) async {
    if (!_selectedNumbers.contains(number)) {
      _selectedNumbers.add(number);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('selectedNumbers',
          _selectedNumbers.map((e) => e.toString()).toList());
      setState(() {}); // Refresh UI
    }
  }

  Future<void> _toggleFilterUsedNumbers(bool value) async {
    setState(() {
      _filterUsedNumbers = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('filterUsedNumbers', value);
  }

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
      final String data = await rootBundle.loadString('lib/data/tao_data.json');
      final List<dynamic> jsonList = jsonDecode(data);

      final List<TaoData> taoDataList = [];

      for (final json in jsonList) {
        final taoData = TaoData.fromJson(json);
        if (taoData.number > 0) {
          taoDataList.add(taoData);
        }
      }

      taoDataList.sort((a, b) => a.number.compareTo(b.number));

      print('✅ Successfully loaded ${taoDataList.length} Tao entries from local JSON');

      for (int i = 0; i < 3 && i < taoDataList.length; i++) {
        final tao = taoDataList[i];
        print('🎵 Tao ${tao.number} - Audio URLs:');
        print('   Audio1: "${tao.audio1}"');
        print('   Audio2: "${tao.audio2}"');
        print('   Audio3: "${tao.audio3}"');
      }

      setState(() {
        _taoDataList = taoDataList;
        _isLoading = false;
        _hasError = false;
      });

    } catch (e) {
      print('❌ Error parsing local JSON data: $e');
      throw Exception('Failed to parse local Tao data');
    }
  }



  void _showFallbackData() {
    print('🔄 Using comprehensive fallback data');

    final List<TaoData> fallbackData = [];

    for (int i = 1; i <= 81; i++) {
      fallbackData.add(TaoData(
        number: i,
        title: 'Tao Chapter $i',
        text: _getFallbackTaoText(i),
        notes: 'Sample notes for Tao $i. This is fallback data while we resolve connection issues.',
        audio1: '',
        audio2: '',
        audio3: '',
      ));
    }

    setState(() {
      _taoDataList = fallbackData;
      _isLoading = false;
      _hasError = false;
    });
  }

  String _getFallbackTaoText(int chapter) {
    final samples = {
      1: 'The Tao that can be told is not the eternal Tao. The name that can be named is not the eternal name.',
      2: 'When people see some things as beautiful, other things become ugly. When people see some things as good, other things become bad.',
      81: 'True words aren\'t eloquent; eloquent words aren\'t true. Wise men don\'t need to prove their point; men who need to prove their point aren\'t wise.',
    };

    return samples[chapter] ?? 'The Tao Te Ching teaches us about the natural way of the universe. Chapter $chapter offers wisdom about harmony and balance.';
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

  Future<bool> _canSelectNewNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final currentDate = DateFormat('yyyyMMdd').format(DateTime.now());
    final lastSelectedDate = prefs.getString('selectedNumberDate') ?? '';

    return lastSelectedDate != currentDate;
  }

  //Future<bool> _canSelectNewNumberForTesting() async {
    //return true; // Always allow selection during testing
    // return await _canSelectNewNumber(); // Use this for production
  //}

  Future<void> _saveToTaoJourney(int number) async {
    final prefs = await SharedPreferences.getInstance();
    final currentDate = DateFormat('yyyyMMdd').format(DateTime.now());

    await prefs.setInt('selectedNumber', number);
    await prefs.setString('selectedNumberDate', currentDate);
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
     final canSelectNew = await _canSelectNewNumber(); // Comment this out for testing
    //final canSelectNew = await _canSelectNewNumberForTesting(); // Use this for testing

    if (!canSelectNew) {
      final prefs = await SharedPreferences.getInstance();
      final lastSelected = prefs.getInt('selectedNumber') ?? 0;

      if (canSelectNew) {
        await _saveToTaoJourney(number); // Changed from _saveSelectedNumber
        await _saveSelectedNumber(number); // Keep the original daily save
      }

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
      if (canSelectNew) {
        await _saveSelectedNumber(number);
        await _saveSelectedNumber(number); // Daily limit
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

    return SingleChildScrollView(  // ← This should be the return statement
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [



          Text(  // ← Your existing title
            'Select a Tao Chapter (1-81):',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Number selector
          // Number selector with Tao Journey indicators
          Container(
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
                                : (isDarkMode ? const Color(0xFFD45C33) : const Color(0xFFD45C33)), // Always normal color
                          ),
                        ),
                        // Small dot indicator for Tao Journey numbers
                        if (isInJourney && _filterUsedNumbers)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00), // Your theme colors
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
          ),


          const SizedBox(height: 50),

          // Instructions
          Text(
            'Swipe horizontally',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
              fontSize: 15,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),

          // Buttons
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

          // Daily limit message
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

          // Tao Journey toggle



          Container(
            padding: const EdgeInsets.only(top: 20),
            child: Column(
              children: [
                // Simple toggle only
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 20,
                      color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00), // Your theme colors
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
                      onChanged: (value) {
                        _toggleFilterUsedNumbers(value);
                      },
                      activeColor: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00), // Your theme colors
                    ),
                  ],
                ),

                // ONLY show these when toggle is ON
                if (_filterUsedNumbers) ...[
                  SizedBox(height: 16),

                  // Progress indicator
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Tao Journey: ${_selectedNumbers.length}/81 explored',
                      style: TextStyle(
                        color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00), // Your theme colors
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Reset button (only show if there are selections)
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

// Debug widget (keep this where it was)
          if (!_isLoading && _taoDataList.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[200],
              child: Text(
                'DEBUG: Loaded ${_taoDataList.length} Tao entries\n'
                    'First: ${_taoDataList.first.number} - ${_taoDataList.first.title}\n'
                    'Last: ${_taoDataList.last.number} - ${_taoDataList.last.title}',
                style: const TextStyle(fontSize: 10, color: Colors.black87),
              ),
            ),
          ],

        ],
      ),
    );
  }
}

class TaoDetailPage extends StatefulWidget {
  final TaoData taoData;

  const TaoDetailPage({super.key, required this.taoData});

  @override
  _TaoDetailPageState createState() => _TaoDetailPageState();
}

class _TaoDetailPageState extends State<TaoDetailPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAudioPlaying = false;
  bool _isPlayerVisible = false;
  String? _currentAudioUrl;
  String? _currentAudioLabel;


  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      setState(() {
        _isAudioPlaying = state == PlayerState.playing;
      });
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isAudioPlaying = false;
      });
    });
  }


  void _showNotesDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          title: Text(
            'Notes for Tao ${widget.taoData.number}',
            style: TextStyle(color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00)),
          ),
          content: SingleChildScrollView(
            child: Text(
              widget.taoData.notes.isNotEmpty ? widget.taoData.notes : 'No notes available for this Tao.',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black87,
                height: 1.6, // Better line spacing
              ),
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

    Widget _buildAudioPlayer(BuildContext context, String audioUrl, String label, int index) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (audioUrl.isEmpty || audioUrl == 'NULL' || audioUrl.trim().isEmpty) {
      return const SizedBox();
    }

    final isCurrentAudio = _currentAudioUrl == audioUrl && _isPlayerVisible;

    return Card(
      color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
      child: ListTile(
        leading: Icon(
          Icons.audiotrack,
          color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
        ),
        title: Text(
          '$label $index', // This will now be "Discussion 1"
          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
        ),
        subtitle: Row(
          children: [
            Text(isCurrentAudio ? 'Now Playing' : 'Tap to listen'),
            const SizedBox(width: 8),
            Icon(Icons.speed, size: 12),
            const Text(' 2x available', style: TextStyle(fontSize: 10)),
          ],
        ),
        trailing: isCurrentAudio ? const Icon(Icons.volume_up) : null,
        onTap: () => _playAudio(context, audioUrl, '$label $index'),
      ),
    );
  }

  Future<void> _playAudio(BuildContext context, String audioUrl, String label) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    try {
      // Stop any currently playing audio
      await _audioPlayer.stop();
      await _resetAudioSpeed();

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loading $label...'),
          backgroundColor: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFFAB3300),
          duration: const Duration(seconds: 2),
        ),
      );

      // Set the audio source and play
      await _audioPlayer.setSource(UrlSource(audioUrl));
      await _audioPlayer.setPlaybackRate(1.0); // Reset to normal speed
      await _audioPlayer.resume();

      // Update state to show the player
      setState(() {
        _currentAudioUrl = audioUrl;
        _currentAudioLabel = label;
        _isPlayerVisible = true;
        _isAudioPlaying = true;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing audio: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Add this method to reset speed when switching audio
  Future<void> _resetAudioSpeed() async {
    try {
      await _audioPlayer.setPlaybackRate(1.0); // Reset to normal speed
    } catch (e) {
      print('Error resetting speed: $e');
    }
  }

  Widget _buildAudioDisclaimer() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? const Color(0xFFFFD26F) : const Color(0xFF7E1A00); // ← NEW
    final iconColor = isDarkMode ? const Color(0xFFFFD26F) : const Color(0xFF7E1A00);

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: (isDarkMode ? const Color(0xFFFFD26F) : const Color(0xFFFFD26F)).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8), // ← This should work for rounded corners
        border: Border.all(color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00)),
      ), // ← REMOVE the semicolon here
      child: Column( // ← This should be directly after the decoration
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: iconColor, size: 16),
              const SizedBox(width: 8),
              Text(
                'Audio Discussion Note',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'The audio discussions may reference various translations. While the wording may vary, the essential wisdom remains aligned with Taoist philosophical principles. These are educational discussions, not definitive interpretations.',
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async {
        await _audioPlayer.stop();
        final currentDate = DateFormat('yyyyMMdd').format(DateTime.now());
        final prefs = await SharedPreferences.getInstance();
        final selectedDate = prefs.getString('selectedNumberDate') ?? '';

        if (selectedDate == currentDate) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Please contemplate today\'s Tao. You can select a new one tomorrow.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFFAB3300),
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 6,
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Tao ${widget.taoData.number}',
            textAlign: TextAlign.center,
          ),
          backgroundColor: isDarkMode ? const Color(0xFF5C1A00) : const Color(0xFF7E1A00),
          automaticallyImplyLeading: false,
          actions: [
            MenuDialogs.buildMenuButton(context),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.taoData.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              Card(
                color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SelectableText(
                    widget.taoData.text.isNotEmpty ? widget.taoData.text : 'Text not available for this Tao.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _showNotesDialog(context),
                  icon: const Icon(Icons.note),
                  label: const Text('Read Notes'),
                ),
              ),
              const SizedBox(height: 30),

              _buildAudioDisclaimer(),
              const SizedBox(height: 16),

              Text(
                'Discussions:',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                ),
              ),
              const SizedBox(height: 10),

              _buildAudioPlayer(context, widget.taoData.audio1, 'Discussion', 1),
              _buildAudioPlayer(context, widget.taoData.audio2, 'Discussion', 2),
              _buildAudioPlayer(context, widget.taoData.audio3, 'Discussion', 3),

              if (widget.taoData.audio1.isEmpty && widget.taoData.audio2.isEmpty && widget.taoData.audio3.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No discussion audio available for this Tao yet.',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (_isPlayerVisible && _currentAudioUrl != null && _currentAudioLabel != null)
                PersistentAudioPlayer(
                  key: ValueKey(_currentAudioUrl),
                  audioPlayer: _audioPlayer,
                  title: _currentAudioLabel!,
                  audioUrl: _currentAudioUrl!,
                  onClose: () async {
                    await _audioPlayer.stop();
                    setState(() {
                      _isPlayerVisible = false;
                      _currentAudioUrl = null;
                      _currentAudioLabel = null;
                      _isAudioPlaying = false;
                    });
                  },
                ),

              const SizedBox(height: 30),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isDarkMode ? const Color(0xFFAB3300) : const Color(0xFF7E1A00)).withOpacity(0.1), // ← UPDATED
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00)), // ← UPDATED
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 40,
                      color: isDarkMode ? const Color(0xFFFFD26F) : const Color(0xFF7E1A00), // ← UPDATED
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Take time to contemplate today\'s Tao. You can explore a new chapter tomorrow.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: isDarkMode ? const Color(0xFFFFD26F) : const Color(0xFF7E1A00), // ← UPDATED
                      ),
                    ),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

class AudioPlayerDialog extends StatefulWidget {
  final AudioPlayer audioPlayer;
  final String title;
  final String audioUrl;

  const AudioPlayerDialog({
    super.key,
    required this.audioPlayer,
    required this.title,
    required this.audioUrl,
  });

  @override
  _AudioPlayerDialogState createState() => _AudioPlayerDialogState();
}

class _AudioPlayerDialogState extends State<AudioPlayerDialog> {
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isSeeking = false;
  double _playbackSpeed = 1.0;
  final List<double> _availableSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    // Reset state when setting up
    _playerState = PlayerState.stopped;
    _position = Duration.zero;
    _isSeeking = false;

    widget.audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _playerState = state;
        });
      }
    });

    widget.audioPlayer.onDurationChanged.listen((duration) {
      print('Duration: $duration');
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    widget.audioPlayer.onPositionChanged.listen((position) {
      print('Position: $position');
      if (mounted && !_isSeeking) {
        setState(() {
          _position = position;
        });
      }
    });

    // Get initial state
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final state = await widget.audioPlayer.state;
        final duration = await widget.audioPlayer.getDuration();
        final position = await widget.audioPlayer.getCurrentPosition();

        if (mounted) {
          setState(() {
            _playerState = state;
            _duration = duration ?? Duration.zero;
            _position = position ?? Duration.zero;
          });
        }
      } catch (e) {
        print('Error getting initial state: $e');
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    return '$minutes:$seconds';
  }

  Future<void> _seekAudio(double value) async {
    setState(() {
      _isSeeking = true;
    });

    final newPosition = Duration(seconds: (value * _duration.inSeconds).toInt());
    await widget.audioPlayer.seek(newPosition);

    setState(() {
      _position = newPosition;
      _isSeeking = false;
    });
  }

  Future<void> _changePlaybackSpeed(double speed) async {
    try {
      await widget.audioPlayer.setPlaybackRate(speed);
      setState(() {
        _playbackSpeed = speed;
      });
    } catch (e) {
      print('Error changing playback speed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to change playback speed'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showSpeedDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          title: Text(
            'Playback Speed',
            style: TextStyle(color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _availableSpeeds.map((speed) {
              return ListTile(
                title: Text(
                  '${speed}x',
                  style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                ),
                trailing: _playbackSpeed == speed
                    ? Icon(Icons.check, color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00))
                    : null,
                onTap: () {
                  _changePlaybackSpeed(speed);
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _getSpeedLabel() {
    if (_playbackSpeed == 1.0) return 'Normal';
    return '${_playbackSpeed}x';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
      insetPadding: const EdgeInsets.all(16),
      title: Text(
        widget.title,
        style: TextStyle(color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00)),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00)),
            ),
            child: Text(
              'Speed: ${_getSpeedLabel()}',
              style: TextStyle(
                color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),

          Slider(
            value: _duration.inSeconds > 0 ? _position.inSeconds / _duration.inSeconds : 0,
            onChanged: _seekAudio,
            onChangeStart: (_) => _isSeeking = true,
            onChangeEnd: (_) => _isSeeking = false,
            activeColor: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
            inactiveColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_position),
                style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
              ),
              Text(
                _formatDuration(_duration),
                style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.speed, size: 28),
                onPressed: () => _showSpeedDialog(context),
                color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                tooltip: 'Change playback speed',
              ),

              IconButton(
                icon: const Icon(Icons.replay_10, size: 30),
                onPressed: () async {
                  final newPosition = _position - const Duration(seconds: 10);
                  await widget.audioPlayer.seek(newPosition > Duration.zero ? newPosition : Duration.zero);
                },
                color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                tooltip: 'Rewind 10 seconds',
              ),

              IconButton(
                icon: Icon(
                  _playerState == PlayerState.playing ? Icons.pause : Icons.play_arrow,
                  size: 40,
                ),
                onPressed: () {
                  if (_playerState == PlayerState.playing) {
                    widget.audioPlayer.pause();
                  } else {
                    widget.audioPlayer.resume();
                  }
                },
                color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                tooltip: _playerState == PlayerState.playing ? 'Pause' : 'Play',
              ),

              IconButton(
                icon: const Icon(Icons.forward_10, size: 30),
                onPressed: () async {
                  final newPosition = _position + const Duration(seconds: 10);
                  if (newPosition < _duration) {
                    await widget.audioPlayer.seek(newPosition);
                  }
                },
                color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                tooltip: 'Forward 10 seconds',
              ),

              IconButton(
                icon: const Icon(Icons.stop, size: 28),
                onPressed: () async {
                  await widget.audioPlayer.stop();
                  // Reset position after stop
                  if (mounted) {
                    setState(() {
                      _position = Duration.zero;
                      _playerState = PlayerState.stopped;
                    });
                  }
                },
                color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                tooltip: 'Stop',
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.audioPlayer.stop();
            Navigator.pop(context);
          },
          child: Text(
            'Close',
            style: TextStyle(color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00)),
          ),
        ),
      ],
    );
  }
}

class TaoData {
  final int number;
  final String title;
  final String text;
  final String notes;
  final String audio1;
  final String audio2;
  final String audio3;

  TaoData({
    required this.number,
    required this.title,
    required this.text,
    required this.notes,
    required this.audio1,
    required this.audio2,
    required this.audio3,
  });

  factory TaoData.fromJson(Map<String, dynamic> json) {
    // Convert // to \n for proper line breaks
    String formatText(String text) {
      return text.replaceAll('//', '\n').replaceAll('////', '\n\n');
    }

    String formatNotes(String notes) {
      return notes.replaceAll('\\n', '\n');
    }

    return TaoData(
      number: int.tryParse(json['number'].toString()) ?? 0,
      title: json['title']?.toString() ?? 'Untitled',
      text: formatText(json['text']?.toString() ?? 'Text not available'),
      notes: formatNotes(json['notes']?.toString() ?? ''),
      audio1: json['1']?.toString() ?? '',
      audio2: json['2']?.toString() ?? '',
      audio3: json['3']?.toString() ?? '',
    );
  }

  static String _formatTaoText(String rawText) {
    if (rawText.isEmpty) return 'Text not available';

    String text = rawText
        .replaceAll('\\n', '\n')
        .replaceAll('|', '\n')
        .replaceAll(';', '\n')
        .replaceAll('//', '\n')
        .replaceAll('  ', '\n\n');

    if (!text.contains('\n')) {
      text = text
          .replaceAll('. ', '.\n\n')
          .replaceAll('? ', '?\n\n')
          .replaceAll('! ', '!\n\n');
    }

    return text.trim();
  }

  static String _formatNotes(String rawNotes) {
    if (rawNotes.isEmpty) return '';

    return rawNotes
        .replaceAll('\\n', '\n')
        .replaceAll('|', '\n')
        .replaceAll('•', '\n•')
        .replaceAll('- ', '\n- ')
        .trim();
  }

  factory TaoData.empty() {
    return TaoData(
      number: 0,
      title: '',
      text: '',
      notes: '',
      audio1: '',
      audio2: '',
      audio3: '',
    );
  }
}