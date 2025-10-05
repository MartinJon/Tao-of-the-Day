// widgets/audio_player_dialog.dart
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

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
        });
      }
    });

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

  @override
  void dispose() {
    widget.audioPlayer.stop();
    super.dispose();
  }
}