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

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
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

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please complete the form'),
        backgroundColor: Colors.red,
      ));
    }
  }

  // Delete slider image entry
  Future<void> deleteSliderImageEntry(DocumentSnapshot document) async {
    // Show a confirmation dialog
    bool? deleteConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Are you sure you want to delete this image?'),
              const SizedBox(height: 10),
              Image.network(
                document['imageUrl'],
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    // If confirmed, delete the image from Google Drive and Firestore
    if (deleteConfirmed == true) {
      try {
        final imageId = document['imageId'];

        // Delete file from Google Drive
        await deleteFileFromGoogleDrive(imageId);

        // Delete Firestore document
        await document.reference.delete();

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
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
          return const Center(child: CircularProgressIndicator());
        }

        final documents = snapshot.data!.docs;

        if (documents.isEmpty) {
          return const Center(
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.image, size: 20, color: Colors.blueGrey),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            document['imageUrl'],
                            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Image.network(
                      document['imageUrl'],
                      width: 280,
                      height: 180,
                      fit: BoxFit.cover,
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
                    child: const Icon(
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
      appBar:AppBar(
          title: const Text(
            'Upload Sliders',
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
                Text('Note 1: Images must be in size range of 200kb to 1MB'),
                Text('Note 2: Image must be an aspect ratio of 16:9'),
                Text('Note 3: Wait until the upload process complete.'),
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
              InkWell(
                onTap: _pickSliderImageFile,
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.image, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Pick Image', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_sliderImageFile != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.file(
                    _sliderImageFile!,
                    width: 300,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ElevatedButton(
                onPressed: _uploadSliderImage,
                child: const Text(
                  'Upload',
                  style: TextStyle(fontFamily: 'metropolis' ,color: Colors.white,fontWeight: FontWeight.bold,fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                    const SizedBox(height: 20),
                    const Text(
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
