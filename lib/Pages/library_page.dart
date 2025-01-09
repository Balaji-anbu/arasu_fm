import 'package:arasu_fm/Pages/audio_stream.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:arasu_fm/Providers/audio_provider.dart';
import 'package:arasu_fm/Pages/audio_data.dart';

class LikedPodcastPage extends StatelessWidget {
  const LikedPodcastPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 2, 15, 27),
        appBar: AppBar(
          iconTheme: IconThemeData(color: Colors.white),
          title: const Text(
            "Your's Library",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xff213555),
        ),
        body: const Center(
          child: Text(
            'Please log in to view your liked podcasts.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final likedAudiosRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('liked_audios');

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 2, 15, 27),
      appBar: AppBar(
        title: const Text(
          "Your's Library",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xff213555),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: likedAudiosRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset('assets/add_animation.json',
                      height: 180, width: 150),
                  const Text(
                    'Add a podcast to get started!',
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'metropolis',
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }

          final likedPodcasts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: likedPodcasts.length,
            itemBuilder: (context, index) {
              final podcast =
                  likedPodcasts[index].data() as Map<String, dynamic>;

              // Convert podcast data to AudioData object
              final audio = AudioData(
                audioUrl: podcast['audioUrl'] ?? '',
                title: podcast['title'] ?? 'Unknown Title',
                imageUrl: podcast['imageUrl'] ?? '',
                timestamp: podcast['timestamp'],
              );

              return GestureDetector(
                onTap: () {
                  final audioProvider =
                      Provider.of<AudioProvider>(context, listen: false);

                  if (audioProvider.currentAudio?.audioUrl == audio.audioUrl) {
                    // Focus on the currently playing audio
                  } else {
                    // Play the selected podcast
                    audioProvider.playAudio(audio);
                  }
                },
                child: Container(
                  height: 80,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xff213555),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          podcast['imageUrl'] ?? '',
                          height: 100,
                          width: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.image,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      title: Text(
                        podcast['title'] ?? 'Unknown Title',
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          final audioProvider = Provider.of<AudioProvider>(
                              context,
                              listen: false);
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
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
