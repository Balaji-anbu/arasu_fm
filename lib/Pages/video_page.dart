import 'dart:async';

import 'package:arasu_fm/Providers/video_provider.dart';
import 'package:arasu_fm/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

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
      videoProvider.fetchVideos();
      videoProvider.fetchSubscriberCount();

      _refreshTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        if (!videoProvider.isLoading && videoProvider.videos.isNotEmpty) {
          _refreshTimer.cancel();
        } else {
          videoProvider.fetchVideos();
        }
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Watch Videos',
          style: TextStyle(
            color: AppColors.white,
            fontFamily: 'metropolis',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final channelId = context.read<VideoProvider>().channelId;
              final url = 'https://www.youtube.com/channel/$channelId';
              launchUrl(Uri.parse(url));
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
            ),
            child: Row(
              children: [
                SizedBox(
                  height: 40,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Lottie.asset("assets/subscribe.json"),
                  ),
                ),
                const SizedBox(width: 2),
                const Text(
                  'Subscribe',
                  style: TextStyle(
                      color: AppColors.white,
                      fontFamily: "metropolis",
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Consumer<VideoProvider>(
        builder: (context, videoProvider, child) {
          if (videoProvider.isLoading && videoProvider.videos.isEmpty) {
            return Center(child: Lottie.asset("assets/load.json"));
          }

          final videos = videoProvider.videos.toList();

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
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> video) {
    return GestureDetector(
      onTap: () {
        showDialog(
          barrierColor: AppColors.primary,
          barrierDismissible: false,
          context: context,
          builder: (_) {
            final controller = YoutubePlayerController(
              params: const YoutubePlayerParams(
                showFullscreenButton: false,
                showControls: true,
                mute: false,
              ),
            )..loadVideoById(videoId: video['videoId']); // Load the video ID

            return Dialog(
              insetPadding: const EdgeInsets.all(8), // Adjust padding for the dialog
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 50),
                      // Video Player Section
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: YoutubePlayerScaffold(
                          controller: controller,
                          builder: (context, player) {
                            return player;
                          },
                        ),
                      ),
                      const SizedBox(height: 50),
                      // Title Section
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          video['title'],
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'metropolis',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
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
                  color: AppColors.white,
                  fontFamily: "metropolis",
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
