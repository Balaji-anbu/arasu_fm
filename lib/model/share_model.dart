import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

class ShareAppButton extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch the dynamic app download link from Firestore
  Future<String> fetchAppDownloadLink() async {
    try {
      // Attempt to get the document from Firestore
      DocumentSnapshot snapshot =
          await _firestore.collection('appConfig').doc('appDownloadLink').get();

      // Check if the document exists
      if (snapshot.exists && snapshot.data() != null) {
        // Return the app link if available
        return snapshot['link'] ??
            'https://default-app-link.com'; // Default link if not available
      } else {
        print('Firestore document not found. Returning default link.');
        return 'https://default-app-link.com'; // Default link if document doesn't exist
      }
    } on FirebaseException catch (e) {
      // Specific Firebase exception handling
      print('Error fetching app download link from Firestore: ${e.message}');
      return 'https://default-app-link.com'; // Default link on Firebase error
    } catch (e) {
      // General error handling
      print('Unknown error while fetching app download link: $e');
      return 'https://default-app-link.com'; // Default link on unknown error
    }
  }

  // Share the app download link
  Future<void> shareApp() async {
    try {
      String appDownloadLink = await fetchAppDownloadLink();
      String shareMessage =
          "Check out Our amazing podcast app: $appDownloadLink";

      // Attempt to share the link
      await Share.share(shareMessage,
          subject: "Download Arasu FM 90.4MHz podcast app!");
      print('App link shared successfully!');
    } catch (e) {
      // Catch errors that occur during sharing
      print('Error sharing app: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.share,
        size: 30,
        color: Colors.white,
      ),
      iconSize: 40,
      onPressed: () async {
        // Trigger sharing when pressed
        print('Share button pressed!');
        await shareApp();
      },
    );
  }
}
