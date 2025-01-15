import 'dart:async';

import 'package:arasu_fm/Providers/video_provider.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({Key? key}) : super(key: key);

  @override
  _VideoPageState createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  late Timer _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final videoProvider = context.read<VideoProvider>();
      videoProvider.fetchVideos(); // Automatically load videos
      videoProvider.fetchSubscriberCount();

      // Add a timer to check for loading state and refresh until data loads
      _refreshTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        if (!videoProvider.isLoading && videoProvider.videos.isNotEmpty) {
          // Stop refreshing when videos are loaded
          _refreshTimer.cancel();
        } else {
          videoProvider.fetchVideos(); // Keep fetching until data is loaded
        }
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer.cancel(); // Clean up the timer when the page is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 2, 15, 27),
      appBar: AppBar(
        backgroundColor: const Color(0xff213555),
        title: const Text(
          'Watch Videos',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'metropolis',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              final channelId = context.read<VideoProvider>().channelId;
              final url = 'https://www.youtube.com/channel/$channelId';
              launchUrl(Uri.parse(url));
            },
            icon: const Icon(Icons.subscriptions, color: Colors.red),
            label: const Text('Subscribe', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Consumer<VideoProvider>(
        builder: (context, videoProvider, child) {
          if (videoProvider.isLoading && videoProvider.videos.isEmpty) {
            return Center(child: Lottie.asset("assets/load.json"));
          }

          final videos = videoProvider.videos.toList(); // Latest videos on top

          return NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
                  !videoProvider.isLoadingMore) {
                videoProvider.fetchVideos(loadMore: true);
              }
              return false;
            },
            child: ListView.builder(
  itemCount: videos.length + (videoProvider.isLoadingMore ? 1 : 0),
  itemBuilder: (context, index) {
    if (index < videos.length) {
      final video = videos[index];
      return _buildVideoCard(video);
    } else {
      return Center(child: Lottie.asset("assets/load.json"));
    }
  },
)

          );
        },
      ),
    );
  }


  Widget _buildVideoCard(Map<String, dynamic> video) {
    return GestureDetector(
      onTap: () {
        showDialog(barrierColor: const Color.fromARGB(255, 2, 15, 27),
        barrierDismissible: false,
          context: context,
          builder: (_) {
            return Dialog(
              
              insetPadding: const EdgeInsets.all(1),
              child: YoutubePlayer(
                controller: YoutubePlayerController(
                  initialVideoId: video['videoId'],
                  flags: const YoutubePlayerFlags(
                    autoPlay: true,
                    mute: false,
                  ),
                ),
              ),
            );
          },
        );
      },
      child: Card(
        color: Colors.grey[900],
        margin: const EdgeInsets.all(8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CachedNetworkImage(
              imageUrl: video['thumbnail'],
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: Colors.grey[700]!,
                highlightColor: Colors.grey[500]!,
                child: Container(
                  height: 200,
                  color: Colors.grey[800],
                ),
              ),
              errorWidget: (context, url, error) => const Icon(
                Icons.broken_image,
                size: 50,
                color: Colors.grey,
              ),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              imageBuilder: (context, imageProvider) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                video['title'],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
