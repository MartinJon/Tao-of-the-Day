// services/audio_service.dart
// lib/services/audio_service.dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';

class AudioService with ChangeNotifier {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;

  AudioService._internal() {
    _setupAudioPlayer();
  }

  final AudioPlayer _audioPlayer = AudioPlayer();

  // Centralized state
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
    // --- iOS Background Audio Configuration ---
    if (!kIsWeb && Platform.isIOS) {
      final audioContext = AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {
            AVAudioSessionOptions.mixWithOthers,
            AVAudioSessionOptions.allowBluetooth,
            AVAudioSessionOptions.defaultToSpeaker,
          },
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ),
      );

      AudioPlayer.global.setAudioContext(audioContext);
    }

    // --- State listeners ---
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

      // If it's a new audio, load it
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

  // Lifecycle hooks – keep empty so background audio is allowed
  void onAppPaused() {
    // Intentionally left empty to allow background playback.
    // If you ever want Android-only pause-on-background:
    // if (Platform.isAndroid && isPlaying) pauseAudio();
  }

  void onAppResumed() {
    // No special handling needed right now.
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

