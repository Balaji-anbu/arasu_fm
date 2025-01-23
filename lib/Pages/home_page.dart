import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:arasu_fm/model/scroll_text.dart';
import 'package:arasu_fm/Pages/audio_data.dart';
import 'package:arasu_fm/Pages/audio_stream.dart';
import 'package:arasu_fm/Providers/audio_provider.dart';
import 'package:flutter/services.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:arasu_fm/Pages/video_page.dart';
import 'package:arasu_fm/Pages/library_page.dart';
import 'package:arasu_fm/Pages/profile_page.dart';

import 'package:flutter/services.dart';  // Add this import at the top

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  List<AudioData> _audioList = [];
  List<AudioData> _audioList1 = [];
  List<String> _sliderImages = [];
  bool _isLoading = true;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int _selectedIndex = 0;
  late AnimationController _rotationController;
   DateTime? _lastBackPressTime;



  @override
  void initState() {
    super.initState();
    _simulateLoading();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _simulateLoading() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Added reasonable delay
    await Future.wait([
      _fetchAudioData(),
      loadSliderImages(),
      fetchFeaturedPodcasts()
    ]);
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<String>> fetchSliderImages() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('slider_images')
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs.map((doc) => doc['imageUrl'] as String).toList();
    } catch (e) {
      debugPrint('Error fetching slider images: $e');
      return [];
    }
  }


  Future<bool> _onWillPop() async {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
      return false;
    }
    
    // On home page, handle double-tap exit
    if (_lastBackPressTime == null || 
        DateTime.now().difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = DateTime.now();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }
    return true;
  }


  Future<void> loadSliderImages() async {
    try {
      final images = await fetchSliderImages();
      if (mounted) {
        setState(() {
          _sliderImages = images;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error loading slider images: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _fetchAudioData() async {
    if (!mounted) return;
    
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('media')
          .orderBy('timestamp', descending: true)
          .get();
      final List<AudioData> fetchedAudioList = querySnapshot.docs.map((doc) {
        return AudioData(
          audioUrl: doc['audioUrl'] as String,
          imageUrl: doc['imageUrl'] as String,
          title: doc['title'] as String,
          timestamp: doc['timestamp'],
        );
      }).toList();

      if (mounted) {
        setState(() {
          _audioList = fetchedAudioList;
        });
        audioProvider.setAudioList(_audioList);
      }
    } catch (e) {
      debugPrint('Error fetching audio data: $e');
    }
  }

  Future<void> fetchFeaturedPodcasts() async {
    if (!mounted) return;
    
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('featured_podcast')
          .orderBy('timestamp', descending: true)
          .get();
      final List<AudioData> fetchedAudioList1 = querySnapshot.docs.map((doc) {
        return AudioData(
          audioUrl: doc['audioUrl'] as String,
          imageUrl: doc['imageUrl'] as String,
          title: doc['title'] as String,
          timestamp: doc['timestamp'],
        );
      }).toList();

      if (mounted) {
        setState(() {
          _audioList1 = fetchedAudioList1;
        });
        audioProvider.setAudioList(_audioList1);
      }
    } catch (e) {
      debugPrint('Error fetching featured podcasts: $e');
    }
  }

  void _showTutorialPopup(GlobalKey key) {
    final RenderBox? renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Stack(
          children: [
            Positioned(
              left: position.dx + size.width / 2 - 180,
              top: position.dy + size.height,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 200,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Listening Podcasts',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'metropolis',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'You are currently listening to a podcast.',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'metropolis',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Lottie.asset("assets/tab.json"),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAudioOverlay(AudioProvider audioProvider) {
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

  Widget _buildBottomNavBar() {
    return Container(
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
          _buildNavItem(Icons.home, 0),
          _buildNavItem(Icons.video_collection, 1),
          _buildNavItem(Icons.library_books, 2),
          _buildNavItem(Icons.person, 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    return IconButton(
      icon: Icon(
        icon,
        color: index == _selectedIndex ? const Color(0xFF1ED760) : Colors.grey,
      ),
      onPressed: () => setState(() => _selectedIndex = index),
    );
  }

  Widget _buildHomeContent() {
    final screenSize = MediaQuery.of(context).size;
    final audioProvider = Provider.of<AudioProvider>(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 15),
          // Slider Section
          _isLoading
              ? Shimmer.fromColors(
                  baseColor: Colors.grey[700]!,
                  highlightColor: Colors.grey[500]!,
                  child: Container(
                    height: screenSize.height * 0.25,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[800],
                    ),
                  ),
                )
              : CarouselSlider(
                  options: CarouselOptions(
                    height: screenSize.height * 0.25,
                    autoPlay: true,
                    enlargeCenterPage: true,
                  ),
                  items: _sliderImages.map((imageUrl) {
                    return Builder(
                      builder: (BuildContext context) {
                        return Container(
                          width: screenSize.width,
                          margin: const EdgeInsets.symmetric(horizontal: 5.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Center(
                                child: Lottie.asset("assets/loading.json",
                                    height: 250, width: 250),
                              ),
                              errorWidget: (context, url, error) => const Center(
                                child: Icon(Icons.error, color: Colors.red),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),

          const SizedBox(height: 10),
          ScrollingTextWithGradient(
            text: "Podcasts From: Arasu Engineering College, Kumbakonam.",
            duration: const Duration(seconds: 15),
            gradientColors: [
              Colors.blue.shade300,
              Colors.purple.shade400,
              Colors.pink.shade300,
            ],
          ),

          // New Podcasts Section
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: Text(
                  'New Podcasts',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'metropolis',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildNewPodcastsSection(audioProvider),

          // Featured Section
          const SizedBox(height: 30),
          const Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: Text(
                  "Featured",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'metropolis',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFeaturedSection(audioProvider),

          // Other Podcasts Section
          const SizedBox(height: 30),
          _buildOtherPodcastsSection(audioProvider),

          // Continue Listening Section
          const SizedBox(height: 30),
          _buildContinueListeningSection(audioProvider),

          const SizedBox(height: 50),
          const Text(
            "Ohh! You Reached End",
            style: TextStyle(
                color: Colors.white, fontFamily: "metropolis", fontSize: 16),
          ),
          const Text(
            "Go To Video Section To Explore More!",
            style: TextStyle(
                color: Colors.white, fontFamily: "metropolis", fontSize: 16),
          ),
          const SizedBox(height: 130),
        ],
      ),
    );
  }

  Widget _buildNewPodcastsSection(AudioProvider audioProvider) {
    if (_isLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[700]!,
        highlightColor: Colors.grey[500]!,
        child: Row(
          children: List.generate(6, (index) {
            return Container(
              width: 150,
              height: 150,
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                color: Colors.grey[800],
              ),
            );
          }),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _audioList.take(6).map((audio) => GestureDetector(
          onTap: () {
            audioProvider.playAudio(audio);
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => AudioPlayerPage(
                  audioUrl: audio.audioUrl,
                  audioData: audio,
                ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(0.0, 1.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;
                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                  var offsetAnimation = animation.drive(tween);
                  return SlideTransition(position: offsetAnimation, child: child);
                },
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 10,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: audio.imageUrl,
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 120,
                child: Text(
                  audio.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'metropolis',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildFeaturedSection(AudioProvider audioProvider) {
    if (_isLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[700]!,
        highlightColor: Colors.grey[500]!,
        child: Row(
          children: List.generate(2, (index) {
            return Container(
              width: 180,
              height: 80,
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.grey[800],
              ),
            );
          }),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 80,
          child: PageView.builder(
            itemCount: _audioList1.length,
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final audio = _audioList1[index];
              return GestureDetector(
                onTap: () {
                  audioProvider.playAudio(audio);
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          AudioPlayerPage(
                        audioUrl: audio.audioUrl,
                        audioData: audio,
                      ),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        const begin = Offset(0.0, 1.0);
                        const end = Offset.zero;
                        const curve = Curves.easeInOut;
                        var tween = Tween(begin: begin, end: end)
                            .chain(CurveTween(curve: curve));
                        var offsetAnimation = animation.drive(tween);
                        return SlideTransition(
                          position: offsetAnimation,
                          child: child,
                        );
                      },
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 3,
                  color: const Color.fromARGB(255, 36, 36, 66),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.grey[850],
                          backgroundImage:
                              CachedNetworkImageProvider(audio.imageUrl),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            audio.title,
                            style: const TextStyle(
                              fontFamily: "metropolis",
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        SmoothPageIndicator(
          controller: _pageController,
          count: _audioList1.length,
          effect: const WormEffect(
            dotHeight: 8,
            dotWidth: 8,
            spacing: 8,
            dotColor: Colors.grey,
            activeDotColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildOtherPodcastsSection(AudioProvider audioProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.0),
              child: Text(
                'Other Podcasts',
                style: TextStyle(
                  fontFamily: 'metropolis',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _isLoading
            ? Shimmer.fromColors(
                baseColor: Colors.grey[700]!,
                highlightColor: Colors.grey[500]!,
                child: Column(
                  children: List.generate(5, (index) {
                    return Container(
                      height: 80,
                      margin: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 10.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[800],
                      ),
                    );
                  }),
                ),
              )
            : ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount:
                    _audioList.length > 6 ? (_audioList.length - 6).clamp(0, 6) : 0,
                itemBuilder: (context, index) {
                  final audio = _audioList[index + 6];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 10.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    color: const Color.fromARGB(255, 30, 43, 65),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(10.0),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: audio.imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(
                        audio.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'metropolis',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.play_arrow, color: Colors.white),
                        onPressed: () {
                          audioProvider.playAudio(audio);
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) =>
                                  AudioPlayerPage(
                                audioUrl: audio.audioUrl,
                                audioData: audio,
                              ),
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                const begin = Offset(0.0, 1.0);
                                const end = Offset.zero;
                                const curve = Curves.easeInOut;
                                var tween = Tween(begin: begin, end: end)
                                    .chain(CurveTween(curve: curve));
                                var offsetAnimation = animation.drive(tween);
                                return SlideTransition(
                                  position: offsetAnimation,
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildContinueListeningSection(AudioProvider audioProvider) {
    if (_audioList.length <= 12) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.0),
              child: Text(
                'Continue Listening',
                style: TextStyle(
                  fontFamily: 'metropolis',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.all(6.0),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: _audioList.length - 12,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 3,
            ),
            itemBuilder: (context, index) {
              final audio = _audioList[index + 12];
              return GestureDetector(
                onTap: () {
                  audioProvider.playAudio(audio);
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          AudioPlayerPage(
                        audioUrl: audio.audioUrl,
                        audioData: audio,
                      ),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        const begin = Offset(0.0, 1.0);
                        const end = Offset.zero;
                        const curve = Curves.easeInOut;
                        var tween = Tween(begin: begin, end: end)
                            .chain(CurveTween(curve: curve));
                        var offsetAnimation = animation.drive(tween);
                        return SlideTransition(
                          position: offsetAnimation,
                          child: child,
                        );
                      },
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.primaries[index % Colors.primaries.length]
                        .withOpacity(0.8),
                  ),
                  child: Row(
  children: [
    Expanded(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Text(
          audio.title,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: "metropolis",
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
          maxLines: 2, // Limit to one line
          overflow: TextOverflow.ellipsis, // Add ellipsis if text overflows
        ),
      ),
    ),
    if (audio.imageUrl.isNotEmpty)
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          imageUrl: audio.imageUrl,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
        ),
      ),
  ],
),

                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final GlobalKey animationKey = GlobalKey();
    
    // Determine which content to show based on selected index
    Widget currentPage;
    switch (_selectedIndex) {
      case 1:
        currentPage = const VideoPage();
        break;
      case 2:
        currentPage = const LikedPodcastPage();
        break;
      case 3:
        currentPage = const ProfilePage();
        break;
      default:
        currentPage = _buildHomeContent();
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 2, 15, 27),
        appBar: _selectedIndex == 0 ? AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 70,
          title: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(1.0),
                child: Image.asset(
                  'assets/main.png',
                  height: 50,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 4),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Arasu FM 90.4 MHz',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'metropolis',
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'சமூக பொறுப்பும்!  சமூக  நலனும்....',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'metropolis',
                    ),
                  ),
                ],
              ),
            ],
          ),
          backgroundColor: const Color(0xff213555),
          actions: audioProvider.isPlaying
              ? [
                  GestureDetector(
                    key: animationKey,
                    onTap: () => _showTutorialPopup(animationKey),
                    child: Lottie.asset("assets/tab.json"),
                  ),
                  const SizedBox(width: 2),
                ]
              : [],
        ) : AppBar(
          backgroundColor: const Color(0xff213555),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              setState(() {
                _selectedIndex = 0;
              });
            },
          ),
        ),
        body: Stack(
          children: [
            currentPage,
            if (audioProvider.currentAudio != null)
              Positioned(
                left: 10,
                right: 10,
                bottom: 1,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            AudioPlayerPage(
                          audioUrl: audioProvider.currentAudio!.audioUrl,
                          audioData: audioProvider.currentAudio!,
                        ),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          const begin = Offset(0.0, 1.0);
                          const end = Offset.zero;
                          const curve = Curves.easeInOut;
                          var tween = Tween(begin: begin, end: end)
                              .chain(CurveTween(curve: curve));
                          var offsetAnimation = animation.drive(tween);
                          return SlideTransition(
                            position: offsetAnimation,
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                  child: _buildAudioOverlay(audioProvider),
                ),
              ),
          ],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }
}