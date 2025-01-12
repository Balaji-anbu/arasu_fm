import 'dart:async';
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
import 'package:flutter/widgets.dart'; // Add this line

class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key});

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  List<AudioData> _audioList = [];
  List<String> _sliderImages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _simulateLoading(); // Simulate loading for 2 seconds
  }

  Future<void> _simulateLoading() async {
    await Future.delayed(const Duration(seconds: 3)); // Show shimmer for 2 seconds
    
    await Future.wait([_fetchAudioData(), loadSliderImages()]); // Load data
    setState(() {
      _isLoading = false; // Stop shimmer after data is loaded
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
        backgroundColor: Colors.red,
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

  void _showTutorialPopup(GlobalKey key) {
    final RenderBox renderBox = key.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Stack(
          children: [
            Positioned(
              left: position.dx + size.width / 2 -180,
              top: position.dy + size.height ,
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final audioProvider = Provider.of<AudioProvider>(context);
    final GlobalKey animationKey = GlobalKey(); // Add this line

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 2, 15, 27),
      appBar: AppBar(
  toolbarHeight: 70,
  title: Row(
    children: [
      // Add the logo before the title
      Padding(
        padding: const EdgeInsets.all(1.0),
        child: Image.asset(
          'assets/arasulogo.png', // Replace with your logo asset path
          height: 60,       // Adjust the height of the logo
          fit: BoxFit.contain,
        ),
      ),
      const SizedBox(width: 4), // Add spacing between logo and text
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
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
          const SizedBox(width: 10),
        ]
      : [],
),

      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 15),
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
                              image: DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: const [
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
            _isLoading
                ? Shimmer.fromColors(
                    baseColor: Colors.grey[700]!,
                    highlightColor: Colors.grey[500]!,
                    child: Row(
                      children: List.generate(6, (index) {
                        return Container(
                          width: 120,
                          height: 120,
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
                                  audioProvider.playAudio(audio);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AudioPlayerPage(
                                        audioUrl: audio.audioUrl,
                                        audioData: audio,
                                      ),
                                    ),
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Card(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 10,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          audio.imageUrl,
                                          width: 120,
                                          height: 120,
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
                              ))
                          .toList(),
                    ),
                  ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: const [
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
                : Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // ListView for the first 5 audios
    ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _audioList.length > 6
          ? (_audioList.length - 6).clamp(0, 5)
          : 0,
      itemBuilder: (context, index) {
        final audio = _audioList[index + 6];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          color: const Color.fromARGB(255, 30, 43, 65),
          child: ListTile(
            contentPadding: const EdgeInsets.all(10.0),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                audio.imageUrl,
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
              icon: const Icon(
                Icons.play_arrow,
                color: Colors.white,
              ),
              onPressed: () {
                audioProvider.playAudio(audio);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AudioPlayerPage(
                      audioUrl: audio.audioUrl,
                      audioData: audio,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    ),

    // GridView for the remaining audios
    if (_audioList.length > 11)
      Padding(
        padding: const EdgeInsets.only(top: 6.0,left: 6,right: 6,bottom: 6),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: _audioList.length - 11, // Remaining audios
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Number of cards per row
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 3, // Adjust for card height/width ratio
          ),
          itemBuilder: (context, index) {
            final audio = _audioList[index + 11];
            return GestureDetector(
              onTap: () {
                audioProvider.playAudio(audio);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AudioPlayerPage(
                      audioUrl: audio.audioUrl,
                      audioData: audio,
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.primaries[index % Colors.primaries.length]
                      .withOpacity(0.8), // Dynamic background color
                ),
                child: Stack(
                  children: [
                    if (audio.imageUrl.isNotEmpty)
                      Positioned(
                        top: 4,
                        right: 10,
                        bottom: 4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            audio.imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Text(
                        audio.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
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
),


            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
