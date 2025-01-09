import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:lottie/lottie.dart';

class SliderImageUploadPage extends StatefulWidget {
  @override
  _SliderImageUploadPageState createState() => _SliderImageUploadPageState();
}

class _SliderImageUploadPageState extends State<SliderImageUploadPage> {
  File? _sliderImageFile;
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

  // Store slider image data in Firestore
  Future<void> storeSliderImageInFirestore(
      String title, String imageUrl, String imageId) async {
    try {
      final sliderCollection =
          FirebaseFirestore.instance.collection('slider_images');
      await sliderCollection.add({
        'title': title,
        'imageUrl': imageUrl,
        'imageId': imageId,
        'timestamp': FieldValue.serverTimestamp(),
      });
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

  // Pick slider image file
  Future<void> _pickSliderImageFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
        _sliderImageFile = File(result.files.single.path!);
      });
    }
  }

  // Upload slider image to Google Drive and Firestore
  Future<void> _uploadSliderImage() async {
    if (_title != null && _sliderImageFile != null) {
      setState(() {
        _isUploading = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Uploading slider image, please wait...'),
        backgroundColor: Colors.orange,
      ));

      try {
        final imageResult = await uploadFileToGoogleDrive(_sliderImageFile!,
            'slider_${DateTime.now().millisecondsSinceEpoch}.png');

        await storeSliderImageInFirestore(
          _title!,
          imageResult['link']!,
          imageResult['id']!,
        );

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Slider image uploaded successfully!'),
          backgroundColor: Colors.green,
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error uploading slider image: $e'),
          backgroundColor: Colors.red,
        ));
      } finally {
        setState(() {
          _isUploading = false;
          _sliderImageFile = null;
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

  // Delete slider image entry
  Future<void> deleteSliderImageEntry(DocumentSnapshot document) async {
    try {
      final imageId = document['imageId'];

      // Delete file from Google Drive
      await deleteFileFromGoogleDrive(imageId);

      // Delete Firestore document
      await document.reference.delete();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Slider image deleted successfully!'),
        backgroundColor: Colors.orange,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error deleting slider image: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  // Fetch and display slider images
  Widget _buildSliderImageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('slider_images')
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
              'No slider images found',
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
                subtitle: Row(
                  children: [
                    Icon(Icons.image, size: 20, color: Colors.blueGrey),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        document['imageUrl'],
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                trailing: InkWell(
                  onTap: () => deleteSliderImageEntry(document),
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
        title: Text('Upload Slider Images',
            style: TextStyle(fontFamily: 'metropolis')),
        backgroundColor: Colors.teal,
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _title = value;
                    });
                  },
                ),
              ),
              ElevatedButton.icon(
                onPressed: _pickSliderImageFile,
                icon: Icon(Icons.image),
                label: Text('Pick Image',
                    style: TextStyle(fontFamily: 'metropolis')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _uploadSliderImage,
                child: Text(
                  'Upload',
                  style: TextStyle(fontFamily: 'metropolis'),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  backgroundColor: Colors.teal,
                ),
              ),
              Expanded(
                child: _buildSliderImageList(),
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
