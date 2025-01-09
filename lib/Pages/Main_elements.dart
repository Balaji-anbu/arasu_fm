import 'dart:async';
import 'package:arasu_fm/model/scroll_text.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:arasu_fm/Pages/audio_data.dart';
import 'package:arasu_fm/Pages/audio_stream.dart';
import 'package:arasu_fm/Providers/audio_provider.dart';
import 'package:carousel_slider/carousel_slider.dart';

class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key});

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent>
    with SingleTickerProviderStateMixin {
  List<AudioData> _audioList = [];
  List<String> _sliderImages = [];

  @override
  void initState() {
    super.initState();
    _fetchAudioData(); // Fetch audio data from Firestore
    loadSliderImages(); // Fetch slider images

    // Initialize Animation Controller for scrolling text
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final audioProvider = Provider.of<AudioProvider>(context);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 2, 15, 27),
      appBar: AppBar(
        title: Column(
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
        backgroundColor: const Color(0xff213555),
      ),
      body: _sliderImages.isEmpty
          ? Center(
              child: Lottie.asset('assets/loading.json'),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 15),
                  CarouselSlider(
                    options: CarouselOptions(
                      height: screenSize.height * 0.250,
                      autoPlay: true,
                      enlargeCenterPage: true,
                      onPageChanged: (index, reason) {
                        setState(() {});
                      },
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
                    text:
                        "Podcasts From: Arasu Engineering College, Kumbakonam.",
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
                  SingleChildScrollView(
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
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount:
                        _audioList.length > 6 ? _audioList.length - 6 : 0,
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
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
