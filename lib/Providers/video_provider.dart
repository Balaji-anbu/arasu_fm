import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class VideoProvider with ChangeNotifier {
  final List<String> apiKeys;
  final String channelId;
  final List<Map<String, dynamic>> _videos = [];
  String? _nextPageToken;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _subscriberCount = 0;
  bool _isLoadingSubscriberCount = true;
  int _currentKeyIndex = 0;

  VideoProvider({required this.apiKeys, required this.channelId});

  List<Map<String, dynamic>> get videos => _videos;
  int get subscriberCount => _subscriberCount;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isLoadingSubscriberCount => _isLoadingSubscriberCount;

  String get currentApiKey => apiKeys[_currentKeyIndex];
void _switchApiKey() {
_currentKeyIndex = (_currentKeyIndex + Random().nextInt(apiKeys.length)) % apiKeys.length;
  print('Switching to API key: ${apiKeys[_currentKeyIndex]}');
  notifyListeners();
}

Future<void> fetchVideos({bool loadMore = false}) async {
  if (_isLoading || (loadMore && _isLoadingMore)) return;

  if (loadMore) {
    _isLoadingMore = true;
  } else {
    _isLoading = true;
  }
  notifyListeners();

  final url = Uri.parse(
    'https://www.googleapis.com/youtube/v3/search?part=snippet&channelId=$channelId&maxResults=5&pageToken=${_nextPageToken ?? ''}&key=$currentApiKey',
  );

  print('Fetching videos with URL: $url');  // Log the URL

  try {
    final response = await http.get(url);

    print('Response Status Code: ${response.statusCode}');  // Log the status code
    print('Response Body: ${response.body}');  // Log the response body for debugging

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['items'] == null) {
        print('No items found in the response'); // Log if no items were returned
        return;
      }

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
      print('Videos fetched successfully: ${_videos.length} videos loaded.');
    } else if (response.statusCode == 403) {
      print('API Key Rate Limit Reached, switching key...');
      _switchApiKey();
      await fetchVideos(loadMore: loadMore);
    } else {
      print('Error fetching videos: ${response.statusCode}');  // Log error status
      throw Exception('Failed to fetch videos: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching videos: $e');
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
      'https://www.googleapis.com/youtube/v3/channels?part=statistics&id=$channelId&key=$currentApiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final subscriberCount =
            data['items'][0]['statistics']['subscriberCount'];
        _subscriberCount = int.parse(subscriberCount);
        print('Subscriber count fetched: $_subscriberCount');
      } else if (response.statusCode == 403) {
        print('API Key Rate Limit Reached, switching key...');
        _switchApiKey();
        await fetchSubscriberCount();
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