import 'dart:io';
import 'package:arasu_fm/model/push_notification.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:lottie/lottie.dart';

class UploadPage extends StatefulWidget {
  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  File? _imageFile;
  File? _audioFile;
  String? _title;
  bool _isUploading = false;
  String? _imageFileName;
  String? _audioFileName;

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

  // Store image and audio URLs in Firestore
  Future<void> storeDataInFirestore(String title, String imageUrl,
      String audioUrl, String imageId, String audioId) async {
    try {
      final mediaCollection = FirebaseFirestore.instance.collection('media');
      await mediaCollection.add({
        'title': title,
        'imageUrl': imageUrl,
        'audioUrl': audioUrl,
        'imageId': imageId,
        'audioId': audioId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      await sendPushNotification(title: 'New Podcast', message: 'New Podcast is just Arrived, Tap To Listen!');
    } catch (e) {
      throw Exception('Error storing data in Firestore: $e');
    }
  }

  // Delete file from Google Drive
  Future<void> deleteFileFromGoogleDrive(String fileId) async {
    try {
      final driveApi = await authenticateWithGoogle();
      await driveApi.files.delete(fileId);
    } catch (e) {
      throw Exception('Error deleting file from Google Drive: $e');
    }
  }

  // Pick image file
  Future<void> _pickImageFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
        _imageFile = File(result.files.single.path!);
        _imageFileName = result.files.single.name;  // Store the image file name
      });
    }
  }

  // Pick audio file
  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null) {
      setState(() {
        _audioFile = File(result.files.single.path!);
        _audioFileName = result.files.single.name;  // Store the audio file name
      });
    }
  }

  // Upload files to Google Drive and Firestore
  Future<void> _uploadFiles() async {
    if (_title != null && _imageFile != null && _audioFile != null) {
      setState(() {
        _isUploading = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Uploading files, please wait...'),
        backgroundColor: Colors.orange,
      ));

      try {
        final imageResult = await uploadFileToGoogleDrive(
            _imageFile!, 'image_${DateTime.now().millisecondsSinceEpoch}.png');
        final audioResult = await uploadFileToGoogleDrive(
            _audioFile!, 'audio_${DateTime.now().millisecondsSinceEpoch}.mp3');

        await storeDataInFirestore(
          _title!,
          imageResult['link']!,
          audioResult['link']!,
          imageResult['id']!,
          audioResult['id']!,
        );

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Files uploaded successfully!'),
          backgroundColor: Colors.green,
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error uploading files: $e'),
          backgroundColor: Colors.red,
        ));
      } finally {
        setState(() {
          _isUploading = false;
          _imageFile = null;
          _audioFile = null;
          _title = null;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please complete the form'),
        backgroundColor: Colors.red,
      ));
    }
  }

  // Delete media entry
  Future<void> deleteMediaEntry(DocumentSnapshot document) async {
    // Show a confirmation dialog
    bool shouldDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Media Entry'),
        content: Text('Are you sure you want to delete "${document['title']}"?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete) {
      try {
        final imageId = document['imageId'];
        final audioId = document['audioId'];

        // Delete files from Google Drive
        await deleteFileFromGoogleDrive(imageId);
        await deleteFileFromGoogleDrive(audioId);

        // Delete Firestore document
        await document.reference.delete();

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Media entry deleted successfully!'),
          backgroundColor: Colors.orange,
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error deleting media: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  // Fetch and display media entries
  Widget _buildMediaList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('media')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final documents = snapshot.data!.docs;

        if (documents.isEmpty) {
          return Center(
            child: Text(
              'No media items found',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: documents.length,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          itemBuilder: (context, index) {
            final document = documents[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  document['title'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.image, size: 20, color: Colors.blueGrey),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            document['imageUrl'],
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[700]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.audiotrack,
                            size: 20, color: Colors.blueGrey),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            document['audioUrl'],
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[700]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    // Display the image thumbnail
                    Image.network(
                      document['imageUrl'],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ],
                ),
                trailing: InkWell(
                  onTap: () => deleteMediaEntry(document),
                  borderRadius: BorderRadius.circular(24),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.delete,
                      size: 24,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
            'Upload Podcasts',
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
    icon: Icon(Icons.info, size: 30, color: Colors.black),
    onPressed: () {
      // Show the bottom sheet when the icon is tapped
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,  // Allow bottom sheet to grow in height
        builder: (BuildContext context) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
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
                    labelText: 'Title',
                    labelStyle: TextStyle(color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _title = value;
                    });
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                    onTap: _pickImageFile,
                    borderRadius: BorderRadius.circular(12),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.image, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Pick Image',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _pickAudioFile,
                    borderRadius: BorderRadius.circular(12),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.audiotrack, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Pick Audio',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              if (_imageFile != null)
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.file(
                        _imageFile!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _imageFileName ?? 'No image selected',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              if (_audioFile != null)
                Column(
                  children: [
                    SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _audioFileName ?? 'No audio selected',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              SizedBox(height: 20),
              InkWell(
                onTap: _uploadFiles,
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 48,
                  ),
                  child: Text(
                    'Upload',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _buildMediaList(),
              ),
            ],
          ),
          if (_isUploading)
            Center(
              child: Container(
                width: 300,
                height: 500,
                color: Colors.white,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset('assets/uploading.json', width: 150),
                    SizedBox(height: 20),
                    Text(
                      'Uploading...',
                      style: TextStyle(
                        fontFamily: 'metropolis',
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
