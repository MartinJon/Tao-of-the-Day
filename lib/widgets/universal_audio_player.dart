// lib/widgets/universal_audio_player.dart
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';

class AudioService with ChangeNotifier {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal() {
    _setupAudioPlayer();
  }

  final AudioPlayer _audioPlayer = AudioPlayer();

  String? _currentAudioUrl;
  String? _currentAudioTitle;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _playbackSpeed = 1.0;
  bool _isLoading = false;

  // Getters
  String? get currentAudioUrl => _currentAudioUrl;
  String? get currentAudioTitle => _currentAudioTitle;
  PlayerState get playerState => _playerState;
  Duration get duration => _duration;
  Duration get position => _position;
  double get playbackSpeed => _playbackSpeed;
  bool get isLoading => _isLoading;
  bool get isPlaying => _playerState == PlayerState.playing;

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _playerState = state;
      notifyListeners();
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      _duration = duration;
      notifyListeners();
    });

    _audioPlayer.onPositionChanged.listen((position) {
      _position = position;
      notifyListeners();
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      _playerState = PlayerState.stopped;
      _position = Duration.zero;
      notifyListeners();
    });
  }

  Future<void> playAudio(String url, String title) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_currentAudioUrl != url) {
        await _audioPlayer.stop();
        await _audioPlayer.setSource(UrlSource(url));
        _currentAudioUrl = url;
        _currentAudioTitle = title;
        _position = Duration.zero;
      }

      await _audioPlayer.resume();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> pauseAudio() async {
    await _audioPlayer.pause();
  }

  Future<void> stopAudio() async {
    await _audioPlayer.stop();
    _currentAudioUrl = null;
    _currentAudioTitle = null;
    _position = Duration.zero;
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    await _audioPlayer.setPlaybackRate(speed);
    _playbackSpeed = speed;
    notifyListeners();
  }

  void onAppPaused() {
    if (isPlaying) {
      pauseAudio();
    }
  }
// Add this method to your AudioService class in universal_audio_player.dart
  Future<void> refreshAudioState() async {
    try {
      final currentState = await _audioPlayer.state;
      final currentPosition = await _audioPlayer.getCurrentPosition();

      _playerState = currentState;
      _position = currentPosition ?? Duration.zero;
      notifyListeners();
    } catch (e) {
      print('Error refreshing audio state: $e');
    }
  }
  void onAppResumed() {
    // Refresh the state to sync with actual audio player
    refreshAudioState();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

class UniversalAudioPlayer extends StatelessWidget {
  final String audioUrl;
  final String title;
  final VoidCallback? onClose;
  final bool showCloseButton;

  const UniversalAudioPlayer({
    super.key,
    required this.audioUrl,
    required this.title,
    this.onClose,
    this.showCloseButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioService>(
      builder: (context, audioService, child) {
        final bool isCurrentAudio = audioService.currentAudioUrl == audioUrl;
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        if (!isCurrentAudio) {
          return _buildInactivePlayer(context, audioService, isDarkMode);
        }

        return _buildActivePlayer(context, audioService, isDarkMode);
      },
    );
  }

  Widget _buildInactivePlayer(BuildContext context, AudioService audioService, bool isDarkMode) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
      child: ListTile(
        leading: Icon(
          Icons.play_arrow,
          color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        subtitle: Text(
          'Tap to play',
          style: TextStyle(
            color: isDarkMode ? Colors.white60 : Colors.black54,
          ),
        ),
        onTap: () => audioService.playAudio(audioUrl, title),
      ),
    );
  }

  Widget _buildActivePlayer(BuildContext context, AudioService audioService, bool isDarkMode) {
    final isPlaying = audioService.isPlaying;
    final isLoaded = audioService.duration != Duration.zero;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                      fontSize: 16,
                    ),
                  ),
                ),
                if (showCloseButton && onClose != null) IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                  color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (audioService.isLoading) ...[
              CircularProgressIndicator(
                color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading audio...',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
            ] else if (isLoaded) ...[
              // Speed indicator
              _buildSpeedIndicator(context, audioService, isDarkMode),
              const SizedBox(height: 12),

              // Progress bar
              Slider(
                value: audioService.duration.inSeconds > 0
                    ? audioService.position.inSeconds / audioService.duration.inSeconds
                    : 0,
                onChanged: (value) {
                  final newPosition = Duration(seconds: (value * audioService.duration.inSeconds).toInt());
                  audioService.seek(newPosition);
                },
                activeColor: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                inactiveColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
              ),
              const SizedBox(height: 8),

              // Time labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(audioService.position),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  Text(
                    _formatDuration(audioService.duration),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSpeedButton(context, audioService, isDarkMode),
                  _buildSeekButton(Icons.replay_10, () => audioService.seek(audioService.position - const Duration(seconds: 10)), isDarkMode),
                  _buildPlayPauseButton(context, audioService, isPlaying, isDarkMode),
                  _buildSeekButton(Icons.forward_10, () => audioService.seek(audioService.position + const Duration(seconds: 10)), isDarkMode),

                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedIndicator(BuildContext context, AudioService audioService, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00)).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Speed: ${_getSpeedLabel(audioService.playbackSpeed)}',
        style: TextStyle(
          color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSpeedButton(BuildContext context, AudioService audioService, bool isDarkMode) {
    return IconButton(
      icon: const Icon(Icons.speed, size: 28),
      onPressed: () => _showSpeedDialog(context, audioService, isDarkMode),
      color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
      tooltip: 'Change playback speed',
    );
  }

  Widget _buildSeekButton(IconData icon, VoidCallback onPressed, bool isDarkMode) {
    return IconButton(
      icon: Icon(icon, size: 30),
      onPressed: onPressed,
      color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
      tooltip: icon == Icons.replay_10 ? 'Rewind 10 seconds' : 'Forward 10 seconds',
    );
  }

  Widget _buildPlayPauseButton(BuildContext context, AudioService audioService, bool isPlaying, bool isDarkMode) {
    return IconButton(
      icon: Icon(
        isPlaying ? Icons.pause : Icons.play_arrow,
        size: 40,
      ),
      onPressed: () {
        if (isPlaying) {
          audioService.pauseAudio();
        } else {
          audioService.playAudio(audioUrl, title);
        }
      },
      color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
      tooltip: isPlaying ? 'Pause' : 'Play',
    );
  }

  Widget _buildStopButton(BuildContext context, AudioService audioService, bool isDarkMode) {
    return IconButton(
      icon: const Icon(Icons.stop, size: 28),
      onPressed: () {
        audioService.stopAudio();
        onClose?.call();
      },
      color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
      tooltip: 'Stop',
    );
  }

  void _showSpeedDialog(BuildContext context, AudioService audioService, bool isDarkMode) {
    final List<double> availableSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

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
            children: availableSpeeds.map((speed) {
              return ListTile(
                title: Text(
                  '${speed}x',
                  style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                ),
                trailing: audioService.playbackSpeed == speed
                    ? Icon(Icons.check, color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00))
                    : null,
                onTap: () {
                  audioService.setPlaybackSpeed(speed);
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _getSpeedLabel(double speed) {
    if (speed == 1.0) return 'Normal';
    return '${speed}x';
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}