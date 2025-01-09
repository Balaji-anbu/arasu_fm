import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arasu_fm/Providers/audio_provider.dart';
import 'package:arasu_fm/Pages/audio_stream.dart';
import 'package:arasu_fm/Pages/video_page.dart';
import 'package:arasu_fm/Pages/library_page.dart';
import 'package:arasu_fm/Pages/profile_page.dart';
import 'package:arasu_fm/Pages/Main_elements.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _pages = [
    HomePageContent(),
    VideoPage(),
    LikedPodcastPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          // Using IndexedStack for dynamic page rendering
          IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
          // Always show the overlay if there is an active audio
          Positioned(
            bottom: 68,
            left: 10,
            right: 10,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AudioPlayerPage(
                      audioUrl: audioProvider.currentAudio?.audioUrl ?? "",
                      audioData: audioProvider.currentAudio!,
                    ),
                  ),
                );
              },
              child: AudioPlayerOverlay(audioProvider: audioProvider),
            ),
          ),
          BottomNavigationBarWidget(
            selectedIndex: _selectedIndex,
            onItemTapped: _onItemTapped,
          ),
        ],
      ),
    );
  }
}

class AudioPlayerOverlay extends StatefulWidget {
  final AudioProvider audioProvider;

  const AudioPlayerOverlay({required this.audioProvider, Key? key})
      : super(key: key);

  @override
  _AudioPlayerOverlayState createState() => _AudioPlayerOverlayState();
}

class _AudioPlayerOverlayState extends State<AudioPlayerOverlay> {
  @override
  Widget build(BuildContext context) {
    final audioProvider = widget.audioProvider; // Accessing audioProvider

    return Container(
      key: ValueKey(
          audioProvider.currentAudio?.title), // Add Key to prevent rebuild
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(255, 1, 73, 38),
            const Color.fromARGB(255, 95, 6, 105)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Album Art
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  audioProvider.currentAudio?.imageUrl ??
                      "https://static.vecteezy.com/system/resources/thumbnails/000/583/157/small/wave_sound-15.jpg",
                  height: 50,
                  width: 45,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              // Song Title and Artist
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width *
                        0.4, // Adjust width to prevent overflow
                    child: Text(
                      audioProvider.currentAudio?.title ?? "Start Playing..",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'metropolis',
                      ),
                      overflow:
                          TextOverflow.ellipsis, // Add ellipsis for long text
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Controls (like, pause/play)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.skip_previous,
                  color: Colors.white,
                ),
                onPressed: () {
                  audioProvider.playPrevious(); // Custom next track logic
                },
              ),
              IconButton(
                icon: Icon(
                  audioProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
                onPressed: () {
                  audioProvider.togglePlayPause(); // Custom play/pause logic
                  setState(() {}); // Force update to ensure UI is refreshed
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.skip_next,
                  color: Colors.white,
                ),
                onPressed: () {
                  audioProvider.playNext(); // Custom next track logic
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BottomNavigationBarWidget extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const BottomNavigationBarWidget({
    required this.selectedIndex,
    required this.onItemTapped,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(1),
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(1),
              spreadRadius: 3,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(
                Icons.home,
                color:
                    selectedIndex == 0 ? const Color(0xFF1ED760) : Colors.grey,
              ),
              onPressed: () => onItemTapped(0),
            ),
            IconButton(
              icon: Icon(
                Icons.video_collection,
                color:
                    selectedIndex == 1 ? const Color(0xFF1ED760) : Colors.grey,
              ),
              onPressed: () => onItemTapped(1),
            ),
            IconButton(
              icon: Icon(
                Icons.library_books,
                color:
                    selectedIndex == 2 ? const Color(0xFF1ED760) : Colors.grey,
              ),
              onPressed: () => onItemTapped(2),
            ),
            IconButton(
              icon: Icon(
                Icons.person,
                color:
                    selectedIndex == 3 ? const Color(0xFF1ED760) : Colors.grey,
              ),
              onPressed: () => onItemTapped(3),
            ),
          ],
        ),
      ),
    );
  }
}
