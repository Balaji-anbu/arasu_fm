import 'package:arasu_fm/Providers/audio_provider.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AudioControlButton extends StatefulWidget {
  final AudioProvider audioProvider;

  const AudioControlButton({
    Key? key,
    required this.audioProvider,
  }) : super(key: key);

  @override
  State<AudioControlButton> createState() => _AudioControlButtonState();
}

class _AudioControlButtonState extends State<AudioControlButton> {
  bool _localIsPaused = true;

  @override
  void initState() {
    super.initState();
    _localIsPaused = widget.audioProvider.isPaused;

    // Listen to player state changes
    widget.audioProvider.audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _localIsPaused = !state.playing;
        });
      }
    });
  }

  void _handlePlayPause() {
    setState(() {
      _localIsPaused = !_localIsPaused;
    });
    widget.audioProvider.togglePlayPause();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Show loading animation when the audio is loading
          if (widget.audioProvider.isLoading)
             Lottie.asset(
              'assets/music.json',
              width: 100,
              height: 100,
              fit: BoxFit.contain,
              // Ensure the animation finishes before the play/pause button works again
              onLoaded: (composition) {
                // You can add any further logic here if needed after the animation is fully loaded
              },
            )
          else
            Material(
              color: Colors.transparent,
              child: IconButton(
                icon: Icon(
                  _localIsPaused ? Icons.play_arrow : Icons.pause,
                  color: Colors.white,
                  size: 40,
                ),
                onPressed: widget.audioProvider.isLoading
                    ? null  // Disable the button when loading
                    : _handlePlayPause, // Otherwise, call the play/pause function
                padding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
    );
  }
}
