// services/audio_service.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

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

  // Handle app lifecycle properly
  void onAppPaused() {
    if (isPlaying) {
      pauseAudio();
    }
  }

  void onAppResumed() {
    // Audio will automatically resume if it was playing
    // The audio_player package handles this well
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}