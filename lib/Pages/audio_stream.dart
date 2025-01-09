import 'package:arasu_fm/model/share_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arasu_fm/Pages/audio_data.dart';
import 'package:arasu_fm/Providers/audio_provider.dart';

class AudioPlayerPage extends StatelessWidget {
  final AudioData audioData;

  const AudioPlayerPage(
      {required this.audioData, Key? key, required String audioUrl})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Provider.of<AudioProvider>(context, listen: false);

    String formatDuration(Duration duration) {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final hours = twoDigits(duration.inHours);
      final minutes = twoDigits(duration.inMinutes.remainder(60));
      final seconds = twoDigits(duration.inSeconds.remainder(60));
      return [if (duration.inHours > 0) hours, minutes, seconds].join(':');
    }

    // Get the screen size
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Scaffold(
      body: AnimatedContainer(
        duration: Duration(seconds: 1),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.grey,
              const Color.fromARGB(255, 0, 54, 49),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child:
              Consumer<AudioProvider>(builder: (context, audioProvider, child) {
            return Center(
              child: Padding(
                padding:
                    EdgeInsets.all(screenWidth * 0.05), // Responsive padding
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(
                        screenWidth * 0.02), // Responsive padding
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Card(
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              audioProvider.currentAudio?.imageUrl ??
                                  audioData.imageUrl,
                              height: screenHeight *
                                  0.35, // Responsive image height
                              width:
                                  screenWidth * 0.7, // Responsive image width
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          audioProvider.currentAudio?.title ?? audioData.title,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize:
                                  screenWidth * 0.05), // Responsive font size
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(
                                size: 30,
                                audioProvider.isLiked(audioData)
                                    ? Icons.my_library_books
                                    : Icons.library_add,
                                color: audioProvider.isLiked(audioData)
                                    ? Color.fromARGB(255, 36, 183, 196)
                                    : Colors.white,
                              ),
                              onPressed: () => audioProvider.toggleLike(),
                              iconSize: 40,
                            ),
                            SizedBox(
                                width: screenWidth * 0.2), // Responsive spacing
                            ShareAppButton(),
                          ],
                        ),
                        const SizedBox(height: 10),
                        StreamBuilder<Duration>(
                          stream: audioProvider.audioPlayer.positionStream,
                          builder: (context, snapshot) {
                            final position = snapshot.data ?? Duration.zero;
                            final duration =
                                audioProvider.audioPlayer.duration ??
                                    Duration.zero;
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
                                    if (audioProvider.isPlaying ||
                                        audioProvider.isPaused) {
                                      audioProvider.audioPlayer.seek(Duration(
                                          milliseconds: value.toInt()));
                                    }
                                  },
                                  activeColor:
                                      Color.fromARGB(255, 36, 183, 196),
                                  inactiveColor: Colors.white,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      formatDuration(position),
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'metropolis',
                                          fontSize: screenWidth *
                                              0.04), // Responsive font size
                                    ),
                                    Text(
                                      formatDuration(duration),
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'metropolis',
                                          fontSize: screenWidth *
                                              0.04), // Responsive font size
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: Icon(
                                size: 30,
                                audioProvider.isShuffling
                                    ? Icons.shuffle_on_outlined
                                    : Icons.shuffle,
                              ),
                              onPressed: audioProvider.toggleShuffle,
                              color: audioProvider.isShuffling
                                  ? Color.fromARGB(255, 36, 183, 196)
                                  : Colors.white,
                              iconSize: 30,
                            ),
                            IconButton(
                              icon: const Icon(Icons.skip_previous),
                              onPressed: audioProvider.playPrevious,
                              color: Colors.white,
                              iconSize: 40,
                            ),
                            IconButton(
                              icon: Icon(
                                size: 30,
                                audioProvider.isPaused
                                    ? Icons.play_arrow
                                    : Icons.pause,
                              ),
                              onPressed: audioProvider.togglePlayPause,
                              color: Colors.white,
                              iconSize: 50,
                            ),
                            IconButton(
                              icon: const Icon(Icons.skip_next),
                              onPressed: audioProvider.playNext,
                              color: Colors.white,
                              iconSize: 40,
                            ),
                            IconButton(
                              icon: Icon(
                                size: 30,
                                audioProvider.isReplaying
                                    ? Icons.repeat_on
                                    : Icons.repeat,
                              ),
                              onPressed: audioProvider.toggleReplay,
                              color: audioProvider.isReplaying
                                  ? Color.fromARGB(255, 36, 183, 196)
                                  : Colors.white,
                              iconSize: 30,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
