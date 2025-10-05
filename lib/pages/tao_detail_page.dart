// pages/tao_detail_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:tao_app_fixed_clean/models/tao_data.dart';
import 'package:tao_app_fixed_clean/menu_dialogs.dart';
import 'package:tao_app_fixed_clean/audio_player.dart';
import '../models/tao_data.dart';

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
      if (mounted) {
        setState(() {
          _isAudioPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isAudioPlaying = false;
        });
      }
    });
  }

  Future<void> _safeStopAudio() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  Future<void> _resetAudioSpeed() async {
    try {
      await _audioPlayer.setPlaybackRate(1.0);
    } catch (e) {
      print('Error resetting speed: $e');
    }
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
                height: 1.6,
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
          '$label $index',
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
      await _safeStopAudio();
      await _resetAudioSpeed();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loading $label...'),
          backgroundColor: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFFAB3300),
          duration: const Duration(seconds: 2),
        ),
      );

      await _audioPlayer.setSource(UrlSource(audioUrl));
      await _audioPlayer.setPlaybackRate(1.0);
      await _audioPlayer.resume();

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

  Widget _buildAudioDisclaimer() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? const Color(0xFFFFD26F) : const Color(0xFF7E1A00);
    final iconColor = isDarkMode ? const Color(0xFFFFD26F) : const Color(0xFF7E1A00);

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: (isDarkMode ? const Color(0xFFFFD26F) : const Color(0xFFFFD26F)).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00)),
      ),
      child: Column(
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
        await _safeStopAudio();
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
                    await _safeStopAudio();
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
                  color: (isDarkMode ? const Color(0xFFAB3300) : const Color(0xFF7E1A00)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 40,
                      color: isDarkMode ? const Color(0xFFFFD26F) : const Color(0xFF7E1A00),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Take time to contemplate today\'s Tao. You can explore a new chapter tomorrow.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: isDarkMode ? const Color(0xFFFFD26F) : const Color(0xFF7E1A00),
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
    _safeStopAudio();
    _audioPlayer.dispose();
    super.dispose();
  }
}