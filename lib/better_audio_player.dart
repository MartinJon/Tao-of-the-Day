import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class BetterAudioPlayer extends StatefulWidget {
  final String title;
  final String audioUrl;
  final VoidCallback? onClose;

  const BetterAudioPlayer({
    super.key,
    required this.title,
    required this.audioUrl,
    this.onClose,
  });

  @override
  _BetterAudioPlayerState createState() => _BetterAudioPlayerState();
}

class _BetterAudioPlayerState extends State<BetterAudioPlayer> with WidgetsBindingObserver {
  final AudioPlayer _audioPlayer = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isSeeking = false;
  bool _isLoading = false;
  double _playbackSpeed = 1.0;
  final List<double> _availableSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupAudioPlayer();
    _initializeAudioAndPlay();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('App lifecycle state: $state');

    if (state == AppLifecycleState.paused) {
      print('App going to background - audio should continue playing');
    } else if (state == AppLifecycleState.resumed) {
      _refreshAudioState();
    } else if (state == AppLifecycleState.detached) {
      _audioPlayer.stop();
    }
  }

  Future<void> _initializeAudioAndPlay() async {
    try {
      setState(() => _isLoading = true);

      await _audioPlayer.setSource(UrlSource(widget.audioUrl));
      _duration = await _audioPlayer.getDuration() ?? Duration.zero;

      // FORCE PLAY - regardless of previous state
      await _audioPlayer.seek(Duration.zero); // Reset to beginning
      await _audioPlayer.resume(); // Force play

      setState(() => _isLoading = false);

    } catch (e) {
      print('Error initializing audio: $e');
      setState(() => _isLoading = false);
    }
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _playerState = state;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted && !_isSeeking) {
        setState(() {
          _position = position;
        });
      }
    });

    // Handle audio completion - CLOSE PLAYER WHEN FINISHED
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        // Auto-close the player after a brief delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && widget.onClose != null) {
            widget.onClose!(); // This closes the player
          }
        });
      }
      print('Audio completed - closing player');
    });
  }

  Future<void> _refreshAudioState() async {
    try {
      final currentPosition = await _audioPlayer.getCurrentPosition();
      final currentState = await _audioPlayer.state;

      if (mounted) {
        setState(() {
          _position = currentPosition ?? Duration.zero;
          _playerState = currentState;
        });
      }
    } catch (e) {
      print('Error refreshing audio state: $e');
    }
  }

  Future<void> _playAudio() async {
    try {
      setState(() => _isLoading = true);

      // If audio is finished or near end, reset to beginning
      if (_position >= _duration - const Duration(seconds: 1) && _duration > Duration.zero) {
        await _audioPlayer.seek(Duration.zero);
      }

      await _audioPlayer.resume();
    } catch (e) {
      print('Error playing audio: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pauseAudio() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      print('Error pausing audio: $e');
    }
  }

  Future<void> _changePlaybackSpeed(double speed) async {
    try {
      await _audioPlayer.setPlaybackRate(speed);
      setState(() {
        _playbackSpeed = speed;
      });
    } catch (e) {
      print('Error changing playback speed: $e');
    }
  }

  Future<void> _seekAudio(double value) async {
    if (_duration.inSeconds == 0) return;

    setState(() => _isSeeking = true);
    try {
      final newPosition = Duration(seconds: (value * _duration.inSeconds).toInt());
      await _audioPlayer.seek(newPosition);
    } catch (e) {
      print('Seek error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSeeking = false);
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _getSpeedLabel() {
    if (_playbackSpeed == 1.0) return 'Normal';
    return '${_playbackSpeed}x';
  }

  void _showSpeedDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Playback Speed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _availableSpeeds.map((speed) => ListTile(
            title: Text('${speed}x'),
            trailing: _playbackSpeed == speed ? const Icon(Icons.check) : null,
            onTap: () {
              _changePlaybackSpeed(speed);
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isPlaying = _playerState == PlayerState.playing;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Speed: ${_getSpeedLabel()}',
                style: TextStyle(
                  color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Slider(
              value: _duration.inSeconds > 0 ? _position.inSeconds / _duration.inSeconds : 0,
              onChanged: _seekAudio,
              activeColor: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(_position)),
                Text(_formatDuration(_duration)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.speed),
                  onPressed: () => _showSpeedDialog(context),
                  color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                ),
                IconButton(
                  icon: const Icon(Icons.replay_10),
                  onPressed: () => _audioPlayer.seek(_position - const Duration(seconds: 10)),
                  color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                ),
                IconButton(
                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: isPlaying ? _pauseAudio : _playAudio,
                  color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                  iconSize: 40,
                ),
                IconButton(
                  icon: const Icon(Icons.forward_10),
                  onPressed: () => _audioPlayer.seek(_position + const Duration(seconds: 10)),
                  color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
