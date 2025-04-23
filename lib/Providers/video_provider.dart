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
    // Choose a different API key - randomly select from available keys
    print('Switching API key from index: $_currentKeyIndex');
    if (apiKeys.length <= 1) {
      print('No other API keys available to switch to.');
      return;
    }
    int newIndex;
    do {
      newIndex = Random().nextInt(apiKeys.length);
    } while (newIndex == _currentKeyIndex && apiKeys.length > 1);
    _currentKeyIndex = newIndex;
    print('Switched to API key index: $_currentKeyIndex');
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
      'https://www.googleapis.com/youtube/v3/search?part=snippet&channelId=$channelId&maxResults=5&order=date&pageToken=${_nextPageToken ?? ''}&key=$currentApiKey',
    );

    print('Fetching videos from: ${url.toString().replaceAll(currentApiKey, "API_KEY")}');

    try {
      final response = await http.get(url);

      print('Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['items'] == null) {
          print('No items returned from YouTube API');
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
      } else if (response.statusCode == 403 || response.statusCode == 401) {
        print('API key limit reached or unauthorized. Switching API key.');
        _switchApiKey();
        await fetchVideos(loadMore: loadMore);
      } else {
        print('Error fetching videos: ${response.statusCode}');
        throw Exception('Failed to fetch videos: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception while fetching videos: $e');
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
    _isLoadingSubscriberCount = true;
    notifyListeners();
    
    final url = Uri.parse(
      'https://www.googleapis.com/youtube/v3/channels?part=statistics&id=$channelId&key=$currentApiKey',
    );

    print('Fetching subscriber count from: ${url.toString().replaceAll(currentApiKey, "API_KEY")}');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final subscriberCount =
            data['items'][0]['statistics']['subscriberCount'];
        _subscriberCount = int.parse(subscriberCount);
        print('Subscriber count fetched: $_subscriberCount');
      } else if (response.statusCode == 403 || response.statusCode == 401) {
        print('API key limit reached or unauthorized for subscriber count. Switching API key.');
        _switchApiKey();
        await fetchSubscriberCount();
      } else {
        print('Error fetching subscriber count: ${response.statusCode}');
        throw Exception('Failed to fetch subscriber count');
      }
    } catch (e) {
      print('Exception while fetching subscriber count: $e');
    } finally {
      _isLoadingSubscriberCount = false;
      notifyListeners();
    }
  }

  void _loadFallbackVideos() {
    print('Loading fallback videos');
    final fallbackVideos = [
      {
        'videoId': '-moq7qwNieU',
        'title': 'Arasu FM 90.4 kumbakonam video 001',
        'thumbnail': 'https://img.youtube.com/vi/-moq7qwNieU/hqdefault.jpg',
      },
      {
        'videoId': 'l_ozpnKXqK8',
        'title': 'Arasu FM 90.4 kumbakonam video 002',
        'thumbnail': 'https://img.youtube.com/vi/l_ozpnKXqK8/hqdefault.jpg',
      },
      {
        'videoId': 'yl8ZFJMl7G8',
        'title': 'Arasu FM 90.4 kumbakonam video 003',
        'thumbnail': 'https://img.youtube.com/vi/yl8ZFJMl7G8/hqdefault.jpg',
      },
      {
        'videoId': 'SRPgmcrDctQ',
        'title': 'Arasu FM 90.4 kumbakonam video 004',
        'thumbnail': 'https://img.youtube.com/vi/SRPgmcrDctQ/hqdefault.jpg',
      },
      {
        'videoId': 'LOxCWyjJ5GQ',
        'title': 'Arasu FM 90.4 kumbakonam video 005',
        'thumbnail': 'https://img.youtube.com/vi/LOxCWyjJ5GQ/hqdefault.jpg',
      },
      {
        'videoId': 'u8auyZkvZJk',
        'title': 'Arasu FM 90.4 kumbakonam video 006',
        'thumbnail': 'https://img.youtube.com/vi/u8auyZkvZJk/hqdefault.jpg',
      },
    ];
    _videos.clear();
    _videos.addAll(fallbackVideos);
    notifyListeners();
  }
}