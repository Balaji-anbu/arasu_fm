import 'dart:async';
import 'package:arasu_fm/Pages/radio_card.dart';
import 'package:arasu_fm/theme/colors.dart';
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
import 'package:flutter/services.dart'; // Add this line
import 'package:flutter/widgets.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart'; // Add this line

class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key});

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  List<AudioData> _audioList = [];
  List<AudioData> _audioList1 = [];
  List<String> _sliderImages = [];
  bool _isLoading = true;
  final PageController _pageController = PageController();
  // ignore: unused_field
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _simulateLoading();
  }

  Future<void> _simulateLoading() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Adjusted delay
    await Future.wait([_fetchAudioData(), loadSliderImages(), fetchFeaturedPodcasts()]); // Load data
    setState(() {
      _isLoading = false;
    });
  }

  Future<List<String>> fetchSliderImages() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('slider_images')
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs.map((doc) => doc['imageUrl'] as String).toList();
    } catch (e) {
      throw Exception('Error fetching slider images: $e');
    }
  }

  Future<void> loadSliderImages() async {
    try {
      final images = await fetchSliderImages();
      setState(() {
        _sliderImages = images;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error loading slider images: $e'),
        backgroundColor: AppColors.red,
      ));
    }
  }

  Future<void> _fetchAudioData() async {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('media')
          .orderBy('timestamp', descending: true)
          .get();
      final List<AudioData> fetchedAudioList = querySnapshot.docs.map((doc) {
        return AudioData(
          audioUrl: doc['audioUrl'],
          imageUrl: doc['imageUrl'],
          title: doc['title'],
          timestamp: doc['timestamp'],
        );
      }).toList();

      setState(() {
        _audioList = fetchedAudioList;
      });

      audioProvider.setAudioList(_audioList);
    } catch (e) {
      print('Error fetching audio data: $e');
    }
  }

  Future<void> fetchFeaturedPodcasts() async {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('featured_podcast')
          .orderBy('timestamp', descending: true)
          .get();
      final List<AudioData> fetchedAudioList1 = querySnapshot.docs.map((doc) {
        return AudioData(
          audioUrl: doc['audioUrl'],
          imageUrl: doc['imageUrl'],
          title: doc['title'],
          timestamp: doc['timestamp'],
        );
      }).toList();

      setState(() {
        _audioList1 = fetchedAudioList1;
      });

      audioProvider.setAudioList(_audioList1);
    } catch (e) {
      print('Error fetching audio data: $e');
    }
  }

  void _showTutorialPopup(GlobalKey key) {
    final RenderBox renderBox = key.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    final currentAudioTitle = audioProvider.currentAudio?.title ?? 'Unknown';

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
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Currently Listening',
                        style: TextStyle(
                          color: AppColors.white,
                          fontFamily: 'metropolis',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(thickness: 0.6),
                      Text(
                        '$currentAudioTitle ...',
                        style: const TextStyle(
                          color: Colors.greenAccent,
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final audioProvider = Provider.of<AudioProvider>(context);
    final GlobalKey animationKey = GlobalKey();

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        
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
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final textScaleFactor = MediaQuery.of(context).textScaleFactor;
                  final fontSize = constraints.maxWidth < 300 ? 16.0 : 18.0;
                  final subtitleSize = constraints.maxWidth < 300 ? 10.0 : 12.0;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Arasu FM 90.4 MHz',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontFamily: 'metropolis',
                          fontWeight: FontWeight.w900,
                          fontSize: fontSize / textScaleFactor,
                          height: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'சமூக பொறுப்பும்!  சமூக  நலனும்....',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: subtitleSize / textScaleFactor,
                          fontFamily: 'metropolis',
                          height: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
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
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
          RadioCard(audioData: _audioList.isNotEmpty ? _audioList.first : AudioData(audioUrl: '', imageUrl: '', title: '', timestamp: '')),
            const SizedBox(height: 15),
            _isLoading
                ? Shimmer.fromColors(
                    baseColor: AppColors.textSecondary,
                    highlightColor: AppColors.textSecondary,
                    child: Container(
                      height: screenSize.height * 0.25,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.textSecondary,
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
                                  child: Lottie.asset("assets/loading.json", height: 250, width: 250),
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
            const SizedBox(height: 10),
            
            const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    'New Podcasts',
                    style: TextStyle(
                      color: AppColors.white,
                      fontFamily: 'metropolis',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _isLoading
                ? Shimmer.fromColors(
                    baseColor: Colors.grey[700]!,
                    highlightColor: Colors.grey[500]!,
                    child: Row(
                      children: List.generate(6, (index) {
                        return Container(
                          width: 150,
                          height: 150,
                          margin: const EdgeInsets.symmetric(horizontal: 8.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey[800],
                          ),
                        );
                      }),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _audioList
                          .take(6)
                          .map((audio) => GestureDetector(
                                onTap: () {
                                  audioProvider.playAudio(audio); // Use updated playAudio function
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

                                        return SlideTransition(
                                          position: offsetAnimation,
                                          child: child,
                                        );
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
                                          color: AppColors.white,
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
                              ))
                          .toList(),
                    ),
                  ),
            const SizedBox(height: 30),
            const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    "Featured",
                    style: TextStyle(
                      color: AppColors.white,
                      fontFamily: 'metropolis',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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
                  )
                : Column(
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
                            // Preload the next featured podcast
                            if (index + 1 < _audioList1.length) {
                              audioProvider.setAudioList(_audioList1); // Ensure the list is updated
                              audioProvider.playAudio(_audioList1[index]); // Preload the current audio
                            }
                          },
                          itemBuilder: (context, index) {
                            final audio = _audioList1[index];
                            return GestureDetector(
                              onTap: () {
                                audioProvider.playAudio(audio); // Ensure this method is called
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
                                color: AppColors.secondary,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 45,
                                        backgroundColor: Colors.grey[850],
                                        backgroundImage: CachedNetworkImageProvider(audio.imageUrl),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          audio.title,
                                          style: const TextStyle(
                                            fontFamily: "metropolis",
                                            color: AppColors.white,
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
                        count: _audioList1.isNotEmpty ?_audioList1.length : 1,
                        effect: const WormEffect(
                          dotHeight: 8,
                          dotWidth: 8,
                          spacing: 8,
                          dotColor: AppColors.textSecondary,
                          activeDotColor: AppColors.white,
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 30),
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
                      color: AppColors.white,
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
              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey[800],
              ),
            );
          }),
        ),
      )
    : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: _audioList.length > 6 ? (_audioList.length - 6).clamp(0, 6) : 0,
            itemBuilder: (context, index) {
              final audio = _audioList[index + 6];
              return GestureDetector(
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

                        return SlideTransition(
                          position: offsetAnimation,
                          child: child,
                        );
                      },
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  color: AppColors.secondary,
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
                        color: AppColors.white,
                        fontFamily: 'metropolis',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
                      const SizedBox(height: 30),
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
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_audioList.length > 12)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: _audioList.length - 12, // Remaining audios
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2, // Number of cards per row
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 3.2, // Adjust for better proportions
                            ),
                            itemBuilder: (context, index) {
                              final audio = _audioList[index + 12];

                              return GestureDetector(
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
                                        var tween = Tween(begin: const Offset(0, 1), end: Offset.zero)
                                            .chain(CurveTween(curve: Curves.easeInOut));

                                        return SlideTransition(
                                          position: animation.drive(tween),
                                          child: child,
                                        );
                                      },
                                    ),
                                  );
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.primaries[index % Colors.primaries.length].withOpacity(0.85),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 6,
                                        spreadRadius: 2,
                                        offset: const Offset(2, 4),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      splashColor: Colors.white.withOpacity(0.3),
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
                                              var scaleTween = Tween<double>(begin: 0.9, end: 1.0)
                                                  .chain(CurveTween(curve: Curves.easeInOut));

                                              return ScaleTransition(
                                                scale: animation.drive(scaleTween),
                                                child: child,
                                              );
                                            },
                                          ),
                                        );
                                      },
                                      child: Row(
                                        children: [
                                          if (audio.imageUrl.isNotEmpty)
                                            Hero(
                                              tag: 'audioImage-${audio.audioUrl}',
                                              child: ClipRRect(
                                                borderRadius: const BorderRadius.only(
                                                  topLeft: Radius.circular(10),
                                                  bottomLeft: Radius.circular(10),
                                                ),
                                                child: CachedNetworkImage(
                                                  imageUrl: audio.imageUrl,
                                                  width: 60,
                                                  height: 60,
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) => Container(
                                                    width: 60,
                                                    height: 60,
                                                    color: Colors.grey[300],
                                                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                              child: Text(
                                                audio.title,
                                                style: const TextStyle(
                                                  color: AppColors.white,
                                                  fontFamily: "metropolis",
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  shadows: [
                                                    Shadow(
                                                      offset: Offset(1, 1),
                                                      blurRadius: 2,
                                                      color: Colors.black87,
                                                    ),
                                                  ],
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
            const SizedBox(height: 50),
            const Text("Ohh! You Reached End", style: TextStyle(color: AppColors.textSecondary, fontFamily: "metropolis", fontSize: 14),),
            const Text("Go To Video Section To Explore More! >>>", style: TextStyle(color: AppColors.textSecondary, fontFamily: "metropolis", fontSize: 15),),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
