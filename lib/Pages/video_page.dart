import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

class VideoProvider with ChangeNotifier {
  final String apiKey;
  final String channelId;
  final List<Map<String, dynamic>> _videos = [];
  String? _nextPageToken;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _subscriberCount = 0;
  bool _isLoadingSubscriberCount = true;

  VideoProvider({required this.apiKey, required this.channelId});

  List<Map<String, dynamic>> get videos => _videos;
  int get subscriberCount => _subscriberCount;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isLoadingSubscriberCount => _isLoadingSubscriberCount;

  Future<void> fetchVideos({bool loadMore = false}) async {
    if (_isLoading || (loadMore && _isLoadingMore)) return;

    if (loadMore) {
      _isLoadingMore = true;
    } else {
      _isLoading = true;
    }
    notifyListeners();

    final url = Uri.parse(
      'https://www.googleapis.com/youtube/v3/search?part=snippet&channelId=$channelId&maxResults=5&pageToken=${_nextPageToken ?? ''}&key=$apiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final fetchedVideos = data['items']
            .where((item) => item['id']['kind'] == 'youtube#video')
            .map<Map<String, dynamic>>((item) => {
                  'videoId': item['id']['videoId'],
                  'title': item['snippet']['title'],
                  'thumbnail': item['snippet']['thumbnails']['high']['url'],
                })
            .toList();

        if (loadMore) {
          _videos.addAll(fetchedVideos);
        } else {
          _videos.clear();
          _videos.addAll(fetchedVideos);
        }

        _nextPageToken = data['nextPageToken'];
      } else if (response.statusCode == 403) {
        _loadFallbackVideos();
      } else {
        throw Exception('Failed to fetch videos: ${response.statusCode}');
      }
    } catch (e) {
      _loadFallbackVideos();
    } finally {
      if (loadMore) {
        _isLoadingMore = false;
      } else {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> fetchSubscriberCount() async {
    final url = Uri.parse(
      'https://www.googleapis.com/youtube/v3/channels?part=statistics&id=$channelId&key=$apiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final subscriberCount =
            data['items'][0]['statistics']['subscriberCount'];
        _subscriberCount = int.parse(subscriberCount);
      } else {
        throw Exception('Failed to fetch subscriber count');
      }
    } catch (e) {
      print('Error fetching subscriber count: $e');
    } finally {
      _isLoadingSubscriberCount = false;
      notifyListeners();
    }
  }

  void _loadFallbackVideos() {
    final fallbackVideos = [
      {
        'videoId': 'dQw4w9WgXcQ',
        'title': 'Fallback Video 1',
        'thumbnail': 'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
      },
      {
        'videoId': 'tAGnKpE4NCI',
        'title': 'Fallback Video 2',
        'thumbnail': 'https://img.youtube.com/vi/tAGnKpE4NCI/hqdefault.jpg',
      },
      {
        'videoId': '2Vv-BfVoq4g',
        'title': 'Fallback Video 3',
        'thumbnail': 'https://img.youtube.com/vi/2Vv-BfVoq4g/hqdefault.jpg',
      },
    ];
    _videos.clear();
    _videos.addAll(fallbackVideos);
    notifyListeners();
  }
}

class VideoPage extends StatefulWidget {
  const VideoPage({Key? key}) : super(key: key);

  @override
  _VideoPageState createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final videoProvider = context.read<VideoProvider>();
      videoProvider.fetchVideos();
      videoProvider.fetchSubscriberCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 2, 15, 27),
      appBar: AppBar(
        backgroundColor: Color(0xff213555),
        title: const Text('Watch Videos',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'metropolis',
                fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: () {
              final channelId = context.read<VideoProvider>().channelId;
              final url = 'https://www.youtube.com/channel/$channelId';
              launchUrl(Uri.parse(url));
            },
            icon: const Icon(Icons.subscriptions, color: Colors.red),
            label:
                const Text('Subscribe', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Consumer<VideoProvider>(
        builder: (context, videoProvider, child) {
          if (videoProvider.isLoading && videoProvider.videos.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels ==
                      scrollInfo.metrics.maxScrollExtent &&
                  !videoProvider.isLoadingMore) {
                videoProvider.fetchVideos(loadMore: true);
              }
              return false;
            },
            child: ListView.builder(
              itemCount: videoProvider.videos.length +
                  (videoProvider.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < videoProvider.videos.length) {
                  final video = videoProvider.videos[index];
                  return Card(
                    color: Colors.grey[900],
                    margin: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.network(video['thumbnail']),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            video['title'],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.play_circle_outline,
                              color: Colors.white),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) {
                                return Dialog(
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
                        ),
                      ],
                    ),
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          );
        },
      ),
    );
  }
}
