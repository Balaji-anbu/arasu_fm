import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:arasu_fm/Pages/audio_data.dart';

class AudioProvider with ChangeNotifier {
  final AudioPlayer audioPlayer = AudioPlayer();
  List<AudioData> _audioList = [];
  AudioData? _currentAudio;
  bool _isShuffling = false;
  bool _isReplaying = false;
  bool _isPaused = true;
  bool _isSeeking = false;
  bool _isPlayingNext = false;
  bool _isLoading = false;
  bool _isAudioReady = false;
  bool _isSwitchingTrack = false;
  final Set<String> _likedAudios = {};
  
  // Map to store completion listeners with their identifiers
  final Map<String, Function()> _completionListeners = {};

  AudioProvider() {
    // Player state listener
    audioPlayer.playerStateStream.listen((playerState) async {
      try {
        switch (playerState.processingState) {
          case ProcessingState.completed:
            // Notify all completion listeners
            for (final listener in _completionListeners.values) {
              listener();
            }
            
            if (_isReplaying) {
              await audioPlayer.seek(Duration.zero);
              audioPlayer.play();
            } else {
              if (!_isPlayingNext) {
                _isPlayingNext = true;
                await playNext();
                _isPlayingNext = false;
              }
            }
            break;

          case ProcessingState.ready:
            _isAudioReady = true;
            _isLoading = false;
            notifyListeners();
            break;

          case ProcessingState.idle:
            _isPaused = true;
            notifyListeners();
            break;

          default:
            break;
        }

        _isPaused = !playerState.playing;
        notifyListeners();
      } catch (e, stackTrace) {
        debugPrint('Error in playerStateStream: $e');
        debugPrint('StackTrace: $stackTrace');
      }
    });

    // Error listener
    audioPlayer.playbackEventStream.listen((event) {}, onError: (e, stack) {
      debugPrint('Playback Error: $e');
      _isLoading = false;
      _isPaused = true;
      _isAudioReady = false;
      notifyListeners();
    });

    // Playing stream listener
    audioPlayer.playingStream.listen((playing) {
      if (_isAudioReady) {
        _isPaused = !playing;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  /// Adds a listener that gets called when audio playback completes
  /// Returns an identifier that can be used to remove the listener
  String addAudioCompletionListener(Function() listener) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _completionListeners[id] = listener;
    return id;
  }

  /// Removes a previously added audio completion listener
  /// [id] is the identifier returned by addAudioCompletionListener
  void removeAudioCompletionListener(String id) {
    if (_completionListeners.containsKey(id)) {
      _completionListeners.remove(id);
    }
  }

  Future<void> playAudio(AudioData audio) async {
    if (_isSwitchingTrack) return;
    _isSwitchingTrack = true;

    try {
      _currentAudio = audio;
      _isAudioReady = false;
      _isLoading = true;
      notifyListeners();

      await audioPlayer.stop(); // stop previous audio

      await audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse(audio.audioUrl),
          tag: MediaItem(
            id: audio.audioUrl,
            title: audio.title,
            artUri: Uri.parse(audio.imageUrl),
          ),
        ),
      );

      await audioPlayer.play();

      _isPaused = false;
      _isAudioReady = true;
      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Error in playAudio: $e');
      debugPrint('Stack Trace: $stackTrace');
      _isLoading = false;
      _isPaused = true;
      _isAudioReady = false;
      notifyListeners();
    } finally {
      _isSwitchingTrack = false;
    }
  }

  Future<void> playNext() async {
    if (_audioList.isEmpty || _currentAudio == null) return;

    final currentIndex = _audioList.indexOf(_currentAudio!);
    if (currentIndex < 0) return;

    _isLoading = true;
    notifyListeners();

    final nextIndex = _isShuffling
        ? Random().nextInt(_audioList.length)
        : (currentIndex + 1) % _audioList.length;

    if (nextIndex >= 0 && nextIndex < _audioList.length) {
      await playAudio(_audioList[nextIndex]);
    } else {
      debugPrint('Invalid next index');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> playPrevious() async {
    if (_audioList.isEmpty || _currentAudio == null) return;

    final currentIndex = _audioList.indexOf(_currentAudio!);
    if (currentIndex < 0) return;

    _isLoading = true;
    notifyListeners();

    final prevIndex = _isShuffling
        ? Random().nextInt(_audioList.length)
        : (currentIndex - 1 + _audioList.length) % _audioList.length;

    if (prevIndex >= 0 && prevIndex < _audioList.length) {
      await playAudio(_audioList[prevIndex]);
    } else {
      debugPrint('Invalid previous index');
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleLike() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _currentAudio != null) {
      final userId = user.uid;
      final sanitizedId = sanitizeDocumentId(_currentAudio!.audioUrl);
      final audioData = {
        'audioUrl': _currentAudio!.audioUrl,
        'title': _currentAudio!.title,
        'imageUrl': _currentAudio!.imageUrl,
      };

      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('liked_audios')
          .doc(sanitizedId);

      if (_likedAudios.contains(_currentAudio!.audioUrl)) {
        _likedAudios.remove(_currentAudio!.audioUrl);
        await ref.delete();
      } else {
        _likedAudios.add(_currentAudio!.audioUrl);
        await ref.set(audioData);
      }

      notifyListeners();
    }
  }

  void toggleReplay() {
    _isReplaying = !_isReplaying;
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffling = !_isShuffling;
    notifyListeners();
  }

  void togglePlayPause() {
    try {
      if (_isLoading || !_isAudioReady) return;

      if (audioPlayer.playing) {
        audioPlayer.pause();
        _isPaused = true;
      } else {
        audioPlayer.play();
        _isPaused = false;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('togglePlayPause error: $e');
    }
  }

  void setAudioList(List<AudioData> list) {
    _audioList = list;
    notifyListeners();
  }

  bool isLiked(AudioData audio) => _likedAudios.contains(audio.audioUrl);

  String sanitizeDocumentId(String id) => id.replaceAll(RegExp(r'[^\w\s]+'), '_');

  @override
  void dispose() {
    _completionListeners.clear();
    audioPlayer.dispose();
    super.dispose();
  }

  // Getters
  List<AudioData> get audioList => _audioList;
  AudioData? get currentAudio => _currentAudio;
  bool get isPlaying => audioPlayer.playing;
  bool get isShuffling => _isShuffling;
  bool get isReplaying => _isReplaying;
  bool get isPaused => _isPaused;
  bool get isSeeking => _isSeeking;
  bool get isLoading => _isLoading;
}