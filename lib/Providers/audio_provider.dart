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
  final Set<String> _likedAudios = {};

  AudioProvider() {
    // Listen to player state changes
    audioPlayer.playerStateStream.listen((playerState) async {
      try {
        if (playerState.processingState == ProcessingState.completed) {
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
        } else if (playerState.processingState == ProcessingState.ready) {
          _isAudioReady = true;
          _isLoading = false;
          notifyListeners();
        } else if (playerState.playing) {
          _isPaused = false;
          _isLoading = false;
          notifyListeners();
        } else if (playerState.processingState == ProcessingState.idle) {
          _isPaused = true;
          notifyListeners();
        }
      } catch (e, stackTrace) {
        debugPrint('Error in playerStateStream listener: $e');
        debugPrint('Stack Trace: $stackTrace');
      }
    });

    // Listen to playing state changes
    audioPlayer.playingStream.listen((playing) {
      if (_isAudioReady) {
        _isPaused = !playing;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> playAudio(AudioData audio) async {
    try {
      _currentAudio = audio;
      _isAudioReady = false;
      _isLoading = true;
      notifyListeners();

      if (_currentAudio == null) {
        debugPrint('playAudio called with null _currentAudio');
        return;
      }

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
      notifyListeners();
    } catch (e, stackTrace) {
      _isLoading = false;
      _isPaused = true;
      _isAudioReady = false;
      notifyListeners();
      debugPrint('Error in playAudio: $e');
      debugPrint('Stack Trace: $stackTrace');
    }
  }

  Future<void> playNext() async {
    try {
      // Set loading state to true when switching tracks
      _isLoading = true;
      notifyListeners();

      if (_audioList.isEmpty) {
        debugPrint('Audio list is empty, cannot play next');
        return;
      }

      final currentIndex = _audioList.indexOf(_currentAudio!);

      if (currentIndex < 0) {
        debugPrint('Current audio not found in the list');
        return;
      }

      final nextIndex = _isShuffling
          ? Random().nextInt(_audioList.length)
          : (currentIndex + 1) % _audioList.length;

      if (nextIndex >= 0 && nextIndex < _audioList.length) {
        _currentAudio = _audioList[nextIndex];
        await playAudio(_currentAudio!);
      } else {
        debugPrint('Invalid next track index');
      }
    } catch (e, stackTrace) {
      debugPrint('Error in playNext: $e');
      debugPrint('Stack Trace: $stackTrace');
    }
  }

  Future<void> playPrevious() async {
    try {
      // Set loading state to true when switching tracks
      _isLoading = true;
      notifyListeners();

      if (_audioList.isEmpty) {
        debugPrint('Audio list is empty, cannot play previous');
        return;
      }

      final currentIndex = _audioList.indexOf(_currentAudio!);

      if (currentIndex < 0) {
        debugPrint('Current audio not found in the list');
        return;
      }

      final prevIndex = _isShuffling
          ? Random().nextInt(_audioList.length)
          : (currentIndex - 1 + _audioList.length) % _audioList.length;

      if (prevIndex >= 0 && prevIndex < _audioList.length) {
        _currentAudio = _audioList[prevIndex];
        await playAudio(_currentAudio!);
      } else {
        debugPrint('Invalid previous track index');
      }
    } catch (e, stackTrace) {
      debugPrint('Error in playPrevious: $e');
      debugPrint('Stack Trace: $stackTrace');
    }
  }

  bool isLiked(AudioData audio) {
    return _likedAudios.contains(audio.audioUrl);
  }

  String sanitizeDocumentId(String id) {
    return id.replaceAll(RegExp(r'[^\w\s]+'), '_');
  }

  void toggleLike() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _currentAudio != null) {
      final userId = user.uid;
      final audioData = {
        'audioUrl': _currentAudio!.audioUrl,
        'title': _currentAudio!.title,
        'imageUrl': _currentAudio!.imageUrl,
      };

      final likedAudiosRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('liked_audios');

      final sanitizedAudioUrl = sanitizeDocumentId(_currentAudio!.audioUrl);

      if (_likedAudios.contains(_currentAudio!.audioUrl)) {
        _likedAudios.remove(_currentAudio!.audioUrl);
        await likedAudiosRef.doc(sanitizedAudioUrl).delete();
      } else {
        _likedAudios.add(_currentAudio!.audioUrl);
        await likedAudiosRef.doc(sanitizedAudioUrl).set(audioData);
      }

      notifyListeners();
    }
  }

  void setAudioList(List<AudioData> audioList) {
    if (audioList.isEmpty) {
      debugPrint('setAudioList called with an empty list');
    }
    _audioList = audioList;
    notifyListeners();
  }

  // Getter for _audioList
  List<AudioData> get audioList => _audioList;

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
      debugPrint('Error in togglePlayPause: $e');
    }
  }

  bool get isPlaying => audioPlayer.playing;
  bool get isShuffling => _isShuffling;
  bool get isReplaying => _isReplaying;
  bool get isPaused => _isPaused;
  bool get isSeeking => _isSeeking;
  bool get isLoading => _isLoading;
  AudioData? get currentAudio => _currentAudio;
}
