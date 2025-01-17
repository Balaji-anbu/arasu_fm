import 'package:arasu_fm/controllers/audio_control_button.dart';
import 'package:arasu_fm/model/share_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:arasu_fm/Pages/audio_data.dart';
import 'package:arasu_fm/Providers/audio_provider.dart';

class AudioPlayerPage extends StatefulWidget {
  final AudioData audioData;

  const AudioPlayerPage({
    required this.audioData,
    Key? key, required String audioUrl,
  }) : super(key: key);

  @override
  _AudioPlayerPageState createState() => _AudioPlayerPageState();
}

class _AudioPlayerPageState extends State<AudioPlayerPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return [if (duration.inHours > 0) hours, minutes, seconds].join(':');
  }
Widget _buildNeonRunningBorderImage(
    AudioProvider audioProvider, double screenHeight, double screenWidth) {
  return Padding(
            padding: const EdgeInsets.all(0), // Space for neon glow
            child:
ClipRRect(
  borderRadius: BorderRadius.circular(20),
  child: CachedNetworkImage(
    imageUrl: audioProvider.currentAudio?.imageUrl ?? widget.audioData.imageUrl,
    height: screenHeight * 0.35,
    width: screenWidth * 0.7,
    fit: BoxFit.cover,
    placeholder: (context, url) =>  Center(
      child: Lottie.asset("assets/loading.json",height: 250,width: 250),
    ),
    errorWidget: (context, url, error) => const Icon(Icons.error),
  ),
)
          );
 
}


  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(seconds: 1),
        curve: Curves.easeInOut,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 60, 58, 58),
              Color.fromARGB(255, 2, 15, 27),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Consumer<AudioProvider>(
            builder: (context, audioProvider, child) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.05),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildNeonRunningBorderImage(audioProvider, screenHeight, screenWidth),
                      const SizedBox(height: 16),
                      Text(
                        audioProvider.currentAudio?.title ?? widget.audioData.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: "metropolis",
                          fontSize: screenWidth * 0.05,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              audioProvider.isLiked(widget.audioData)
                                  ? Icons.my_library_books
                                  : Icons.library_add,
                              size: 30,
                              color: audioProvider.isLiked(widget.audioData)
                                  ? const Color.fromARGB(255, 36, 183, 196)
                                  : Colors.white,
                            ),
                            onPressed: () => audioProvider.toggleLike(),
                            iconSize: 40,
                          ),
                          SizedBox(width: screenWidth * 0.2),
                          ShareAppButton(),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildProgressSlider(audioProvider),
                      const SizedBox(height: 20),
                      _buildControlButtons(audioProvider),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSlider(AudioProvider audioProvider) {
    return StreamBuilder<Duration>(
      stream: audioProvider.audioPlayer.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = audioProvider.audioPlayer.duration ?? Duration.zero;
        final clampedValue = position.inMilliseconds
            .clamp(0, duration.inMilliseconds)
            .toDouble();

        return Column(
          children: [
            Slider(
              value: clampedValue,
              min: 0,
              max: duration.inMilliseconds.toDouble(),
              onChanged: (value) {
                if (audioProvider.isPlaying || audioProvider.isPaused) {
                  audioProvider.audioPlayer.seek(
                    Duration(milliseconds: value.toInt()),
                  );
                }
              },
              activeColor: const Color.fromARGB(255, 36, 183, 196),
              inactiveColor: Colors.white,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatDuration(position),
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'metropolis',
                    ),
                  ),
                  Text(
                    formatDuration(duration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'metropolis',
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControlButtons(AudioProvider audioProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(
            audioProvider.isShuffling
                ? Icons.shuffle_on_outlined
                : Icons.shuffle,
            size: 30,
          ),
          onPressed: audioProvider.toggleShuffle,
          color: audioProvider.isShuffling
              ? const Color.fromARGB(255, 36, 183, 196)
              : Colors.white,
        ),
        IconButton(
          icon: const Icon(Icons.skip_previous),
          onPressed: audioProvider.playPrevious,
          color: Colors.white,
          iconSize: 40,
        ),
        AudioControlButton(audioProvider: audioProvider),
        IconButton(
          icon: const Icon(Icons.skip_next),
          onPressed: audioProvider.playNext,
          color: Colors.white,
          iconSize: 40,
        ),
        IconButton(
          icon: Icon(
            audioProvider.isReplaying
                ? Icons.repeat_on
                : Icons.repeat,
            size: 30,
          ),
          onPressed: audioProvider.toggleReplay,
          color: audioProvider.isReplaying
              ? const Color.fromARGB(255, 36, 183, 196)
              : Colors.white,
        ),
      ],
    );
  }
}
