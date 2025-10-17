import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class PersistentAudioPlayer extends StatefulWidget {
  final AudioPlayer audioPlayer;
  final String title;
  final String audioUrl;
  final VoidCallback? onClose;

  const PersistentAudioPlayer({
    super.key,
    required this.audioPlayer,
    required this.title,
    required this.audioUrl,
    this.onClose,
  });

  @override
  _PersistentAudioPlayerState createState() => _PersistentAudioPlayerState();
}

class _PersistentAudioPlayerState extends State<PersistentAudioPlayer> with WidgetsBindingObserver {
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isSeeking = false;
  bool _isLoading = false;
  double _playbackSpeed = 1.0;
  final List<double> _availableSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  void resetSpeed() {
    if (mounted) {
      setState(() {
        _playbackSpeed = 1.0;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupAudioPlayer();
    _getInitialState();
    _configureAudioSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Reset speed when player is disposed
    widget.audioPlayer.setPlaybackRate(1.0);
    super.dispose();
  }

  // Handle app lifecycle (phone sleep, app background)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('App lifecycle state changed: $state');

    if (state == AppLifecycleState.paused) {
      // App going to background - audio should continue
      print('App backgrounded - audio should continue playing');
    } else if (state == AppLifecycleState.resumed) {
      // App coming to foreground - refresh audio state
      _refreshAudioState();
    }
  }

  Future<void> _configureAudioSession() async {
    try {
      // SIMPLIFIED version that will work
      await widget.audioPlayer.setAudioContext(AudioContext(
        android: AudioContextAndroid(
          contentType: AndroidContentType.music,
          stayAwake: true,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
        ),
      ));
      print('✅ Audio session configured for background playback');
    } catch (e) {
      print('❌ Error configuring audio session: $e');
      // Even simpler fallback
      try {
        await widget.audioPlayer.setAudioContext(AudioContext(
          android: AudioContextAndroid(
            contentType: AndroidContentType.music,
          ),
        ));
        print('✅ Fallback audio session configured');
      } catch (e2) {
        print('❌ Fallback audio configuration also failed: $e2');
      }
    }
  }

  void _setupAudioPlayer() {
    widget.audioPlayer.onPlayerStateChanged.listen((state) {
      print('Player state changed to: $state');
      if (mounted) {
        setState(() {
          _playerState = state;
          // Show loading when buffering at the start
          _isLoading = state == PlayerState.playing && _position.inSeconds == 0;
        });
      }
    });

    widget.audioPlayer.onDurationChanged.listen((duration) {
      print('Duration updated: $duration');
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    widget.audioPlayer.onPositionChanged.listen((position) {
      if (mounted && !_isSeeking) {
        setState(() {
          _position = position;
          // Hide loading once we start getting position updates
          if (_isLoading && position.inSeconds > 0) {
            _isLoading = false;
          }
        });
      }
    });
  }

  void _getInitialState() async {
    try {
      // Get the current state when the player loads
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
  }

  Future<void> _refreshAudioState() async {
    try {
      final state = await widget.audioPlayer.state;
      final position = await widget.audioPlayer.getCurrentPosition();

      if (mounted) {
        setState(() {
          _playerState = state;
          _position = position ?? Duration.zero;
        });
      }
    } catch (e) {
      print('Error refreshing audio state: $e');
    }
  }

  Future<void> _changePlaybackSpeed(double speed) async {
    try {
      await widget.audioPlayer.setPlaybackRate(speed);
      setState(() {
        _playbackSpeed = speed;
      });
    } catch (e) {
      print('Error changing playback speed: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _seekAudio(double value) async {
    if (_duration.inSeconds == 0) return;

    setState(() {
      _isSeeking = true;
    });

    try {
      final newPosition = Duration(seconds: (value * _duration.inSeconds).toInt());
      await widget.audioPlayer.seek(newPosition);

      if (mounted) {
        setState(() {
          _position = newPosition;
        });
      }
    } catch (e) {
      print('Seek error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSeeking = false;
        });
      }
    }
  }

  String _getSpeedLabel() {
    if (_playbackSpeed == 1.0) return 'Normal';
    return '${_playbackSpeed}x';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with title and close button only
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
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                  tooltip: 'Close Player',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Speed indicator
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

            // Progress bar with loading indicator
            Stack(
              children: [
                Slider(
                  value: _duration.inSeconds > 0 ? _position.inSeconds / _duration.inSeconds : 0,
                  onChanged: _seekAudio,
                  onChangeStart: (_) => _isSeeking = true,
                  onChangeEnd: (_) => _isSeeking = false,
                  activeColor: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                  inactiveColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                ),
                if (_isLoading)
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Loading...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Time indicators
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

            // Control buttons (removed stop button)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Speed control
                IconButton(
                  icon: const Icon(Icons.speed, size: 28),
                  onPressed: () => _showSpeedDialog(context),
                  color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                  tooltip: 'Change playback speed',
                ),

                // Rewind 10s
                IconButton(
                  icon: const Icon(Icons.replay_10, size: 30),
                  onPressed: _isLoading ? null : () async {
                    try {
                      final newPosition = _position - const Duration(seconds: 10);
                      await widget.audioPlayer.seek(newPosition > Duration.zero ? newPosition : Duration.zero);
                    } catch (e) {
                      print('Rewind error: $e');
                    }
                  },
                  color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                  tooltip: 'Rewind 10 seconds',
                ),

                // Play/Pause with loading state
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        _playerState == PlayerState.playing ? Icons.pause : Icons.play_arrow,
                        size: 40,
                      ),
                      onPressed: _isLoading ? null : () async {
                        setState(() => _isLoading = true);
                        try {
                          if (_playerState == PlayerState.playing) {
                            await widget.audioPlayer.pause();
                            // Force state update
                            if (mounted) {
                              setState(() {
                                _playerState = PlayerState.paused;
                              });
                            }
                          } else {
                            await widget.audioPlayer.resume();
                            // Force state update
                            if (mounted) {
                              setState(() {
                                _playerState = PlayerState.playing;
                              });
                            }
                          }
                        } catch (e) {
                          print('Play/Pause error: $e');
                        } finally {
                          if (mounted) {
                            setState(() => _isLoading = false);
                          }
                        }
                      },
                      color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                      tooltip: _playerState == PlayerState.playing ? 'Pause' : 'Play',
                    ),
                    if (_isLoading)
                      Positioned(
                        child: Container(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // Forward 10s
                IconButton(
                  icon: const Icon(Icons.forward_10, size: 30),
                  onPressed: _isLoading ? null : () async {
                    try {
                      final newPosition = _position + const Duration(seconds: 10);
                      if (newPosition < _duration) {
                        await widget.audioPlayer.seek(newPosition);
                      }
                    } catch (e) {
                      print('Forward error: $e');
                    }
                  },
                  color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                  tooltip: 'Forward 10 seconds',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSpeedDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          insetPadding: const EdgeInsets.all(16),
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
}