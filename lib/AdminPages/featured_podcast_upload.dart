import 'dart:io';
import 'package:arasu_fm/model/push_notification.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:lottie/lottie.dart';

class PodcastAdminPage extends StatefulWidget {
  @override
  _PodcastAdminPageState createState() => _PodcastAdminPageState();
}

class _PodcastAdminPageState extends State<PodcastAdminPage> {
  File? _podcastImageFile;
  File? _podcastAudioFile;
  String? _title;
  bool _isUploading = false;

  // Authenticate with Google Drive API
  Future<drive.DriveApi> authenticateWithGoogle() async {
    try {
      final credentials =
          await rootBundle.loadString('assets/credentials.json');
      final accountCredentials =
          ServiceAccountCredentials.fromJson(credentials);
      final authClient = await clientViaServiceAccount(
          accountCredentials, [drive.DriveApi.driveFileScope]);
      return drive.DriveApi(authClient);
    } catch (e) {
      throw Exception('Error authenticating with Google Drive: $e');
    }
  }

  // Upload file to Google Drive and get the shareable link
  Future<Map<String, String>> uploadFileToGoogleDrive(
      File file, String fileName) async {
    final driveApi = await authenticateWithGoogle();
    final driveFile = drive.File()..name = fileName;
    final media = drive.Media(file.openRead(), file.lengthSync());

    try {
      final uploadedFile =
          await driveApi.files.create(driveFile, uploadMedia: media);

      final permission = drive.Permission()
        ..type = 'anyone'
        ..role = 'reader';
      await driveApi.permissions.create(permission, uploadedFile.id!);

      final fileId = uploadedFile.id!;
      final directDownloadLink = 'https://drive.google.com/uc?id=$fileId';
      return {'id': fileId, 'link': directDownloadLink};
    } catch (e) {
      throw Exception('Error uploading file: $e');
    }
  }

  // Store podcast data in Firestore
  Future<void> storeDataInFirestore(String title, String imageUrl,
      String audioUrl, String imageId, String audioId) async {
    try {
      final mediaCollection = FirebaseFirestore.instance.collection('featured_podcast');
      await mediaCollection.add({
        'title': title,
        'imageUrl': imageUrl,
        'audioUrl': audioUrl,
        'imageId': imageId,
        'audioId': audioId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      await sendPushNotification(title: 'New Featured Podcast', message: 'New Featured Podcast is just Arrived, Tap To Listen!');
    } catch (e) {
      throw Exception('Error storing data in Firestore: $e');
    }
  }

  // Delete podcast data from Firestore and Google Drive
  Future<void> deletePodcast(String imageId, String audioId) async {
    try {
      final driveApi = await authenticateWithGoogle();

      // Delete the files from Google Drive
      await driveApi.files.delete(imageId);
      await driveApi.files.delete(audioId);

      // Delete the document from Firestore
      final mediaCollection = FirebaseFirestore.instance.collection('featured_podcast');
      final querySnapshot = await mediaCollection
          .where('imageId', isEqualTo: imageId)
          .where('audioId', isEqualTo: audioId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.delete();
      }
    } catch (e) {
      throw Exception('Error deleting podcast: $e');
    }
  }

  // Pick image file
  Future<void> _pickImageFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
        _podcastImageFile = File(result.files.single.path!);
      });
    }
  }

  // Pick audio file
  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null) {
      setState(() {
        _podcastAudioFile = File(result.files.single.path!);
      });
    }
  }

  // Upload files and store metadata in Firestore
  Future<void> _uploadPodcast() async {
    if (_title != null &&
        _podcastImageFile != null &&
        _podcastAudioFile != null) {
      setState(() {
        _isUploading = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Uploading podcast, please wait...'),
        backgroundColor: Colors.orange,
      ));

      try {
        final imageResult = await uploadFileToGoogleDrive(
            _podcastImageFile!, 'image_${DateTime.now().millisecondsSinceEpoch}.png');
        final audioResult = await uploadFileToGoogleDrive(
            _podcastAudioFile!, 'audio_${DateTime.now().millisecondsSinceEpoch}.mp3');

        await storeDataInFirestore(
          _title!,
          imageResult['link']!,
          audioResult['link']!,
          imageResult['id']!,
          audioResult['id']!,
        );

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Podcast uploaded successfully!'),
          backgroundColor: Colors.green,
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error uploading podcast: $e'),
          backgroundColor: Colors.red,
        ));
      } finally {
        setState(() {
          _isUploading = false;
          _podcastImageFile = null;
          _podcastAudioFile = null;
          _title = null;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please complete the form'),
        backgroundColor: Colors.red,
      ));
    }
  }

  // Build the podcast upload UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBar(
          title: const Text(
            'Upload Featured',
            style: TextStyle(
              fontFamily: 'metropolis',
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.teal,
          actions: [
           Padding(
  padding: const EdgeInsets.all(8.0),
  child: IconButton(
    icon: const Icon(Icons.info, size: 30, color: Colors.black),
    onPressed: () {
      // Show the bottom sheet when the icon is tapped
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,  // Allow bottom sheet to grow in height
        builder: (BuildContext context) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Important Notes:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 10),
                Text('Note 1: Images must be in size of below 200 kb'),
                Text('Note 2: 512 x 512 pixels is best suitable'),
                Text('Note 3: Audio File must be in Mp3 format'),
                Text('Note 4: Wait until the upload process complete.'),
              ],
            ),
          );
        },
      );
    },
  ),
)

          ],
        ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Podcast Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) => setState(() {
                    _title = value;
                  }),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImageFile,
                    icon: const Icon(Icons.image),
                    label: const Text('Pick Image',
                        style: TextStyle(fontFamily: 'metropolis')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _pickAudioFile,
                    icon: const Icon(Icons.audiotrack),
                    label: const Text('Pick Audio',
                        style: TextStyle(fontFamily: 'metropolis')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                    ),
                  ),
                ],
              ),
              // Show the selected image and audio file names
              if (_podcastImageFile != null) 
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Image.file(_podcastImageFile!, height: 100, fit: BoxFit.cover),
                      const SizedBox(height: 8),
                      Text('Image: ${_podcastImageFile!.path.split('/').last}',
                          style: const TextStyle(fontSize: 16, color: Colors.black)),
                    ],
                  ),
                ),
              if (_podcastAudioFile != null) 
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Audio: ${_podcastAudioFile!.path.split('/').last}',
                      style: const TextStyle(fontSize: 16, color: Colors.black)),
                ),
              const SizedBox(height: 20),
              // InkWell for Upload button
              InkWell(
                onTap: _uploadPodcast,
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Upload',
                      style: TextStyle(fontFamily: 'metropolis', color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // StreamBuilder for Podcast List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('featured_podcast')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No Uploads available.'));
                    }

                    final podcasts = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: podcasts.length,
                      itemBuilder: (context, index) {
                        final podcast = podcasts[index];
                        final imageUrl = podcast['imageUrl'];
                        final audioUrl = podcast['audioUrl'];
                        final title = podcast['title'];
                        final imageId = podcast['imageId'];
                        final audioId = podcast['audioId'];

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          title: Text(title, style: const TextStyle(fontSize: 18)),
                          leading: Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover),
                          subtitle: Text(audioUrl),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              // Show confirmation dialog before deleting
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Delete Podcast'),
                                    content: const Text('Are you sure you want to delete this podcast?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(false);
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(true);
                                        },
                                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (confirmed == true) {
                                await deletePodcast(imageId, audioId);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                  content: Text('Media deleted successfully!'),
                                  backgroundColor: Colors.green,
                                ));
                              }
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          if (_isUploading)
            Center(
              child: Lottie.asset('assets/uploading.json', width: 150),
            ),
        ],
      ),
    );
  }
}
