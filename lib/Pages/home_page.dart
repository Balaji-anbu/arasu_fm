import 'package:arasu_fm/Pages/Main_elements.dart';
import 'package:arasu_fm/Pages/audio_stream.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arasu_fm/Providers/audio_provider.dart';
import 'package:arasu_fm/Pages/video_page.dart';
import 'package:arasu_fm/Pages/library_page.dart';
import 'package:arasu_fm/Pages/profile_page.dart';

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
    HomePageContent(), // Placeholder for the home page content
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
          // Overlay showing current audio if any
          if (audioProvider.currentAudio != null)
            Positioned(
              bottom: 68,
              left: 10,
              right: 10,
              child: GestureDetector(
               onTap: () {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => AudioPlayerPage(
        audioUrl: audioProvider.currentAudio!.audioUrl,
        audioData: audioProvider.currentAudio!,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0); // Start from bottom
        const end = Offset.zero;       // End at the center (normal position)
        const curve = Curves.easeInOut;

        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        final offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    ),
  );
},

                child: AudioPlayerOverlay(audioProvider: audioProvider),
              ),
            ),
          // Bottom navigation bar
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

  const AudioPlayerOverlay({required this.audioProvider, Key? key}) : super(key: key);

  @override
  _AudioPlayerOverlayState createState() => _AudioPlayerOverlayState();
}

class _AudioPlayerOverlayState extends State<AudioPlayerOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = widget.audioProvider;

    if (audioProvider.isPlaying) {
      if (!_rotationController.isAnimating) {
        _rotationController.repeat();
      }
    } else {
      _rotationController.stop();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black87, Colors.grey.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Rotating album art
          AnimatedBuilder(
            animation: _rotationController,
            child: CircleAvatar(
              radius: 25,
              backgroundImage: NetworkImage(
                audioProvider.currentAudio?.imageUrl ??
                    "https://static.vecteezy.com/system/resources/thumbnails/000/583/157/small/wave_sound-15.jpg",
              ),
            ),
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2.0 * 3.14159,
                child: child,
              );
            },
          ),
          const SizedBox(width: 10),
          // Audio details
          Expanded(
            child: Text(
              audioProvider.currentAudio?.title ?? "Playing...",
              style: const TextStyle(
                color: Colors.white,
                fontFamily: "metropolis",
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Play/Pause and Next buttons
          Row(
            children: [
              IconButton(
                icon: Icon(
                  audioProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
                onPressed: audioProvider.togglePlayPause,
              ),
              IconButton(
                icon: const Icon(Icons.skip_next, color: Colors.white),
                onPressed: audioProvider.playNext,
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
          color: Colors.black,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 0, selectedIndex),
            _buildNavItem(Icons.video_collection, 1, selectedIndex),
            _buildNavItem(Icons.library_books, 2, selectedIndex),
            _buildNavItem(Icons.person, 3, selectedIndex),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, int selectedIndex) {
    return IconButton(
      icon: Icon(
        icon,
        color: index == selectedIndex ? const Color(0xFF1ED760) : Colors.grey,
      ),
      onPressed: () => onItemTapped(index),
    );
  }
}
