// ignore_for_file: must_be_immutable

import 'package:arasu_fm/AdminPages/admin_sliderupload.dart';
import 'package:arasu_fm/AdminPages/admin_upload.dart';
import 'package:arasu_fm/AdminPages/featured_podcast_upload.dart';
import 'package:arasu_fm/Pages/onboarding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AdminHome extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? currentUser;

  AdminHome({super.key});

  @override
  // ignore: override_on_non_overriding_member
  void initState() {
    currentUser = _auth.currentUser; // Get the current user
  }

// Logout Function
Future<void> signOut(BuildContext context) async {
  try {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Onboarding()),
      (route) => false,
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to sign out. Please try again.')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel',
            style: TextStyle(fontFamily: 'metropolis')),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            onPressed: () async {
              // Show confirmation dialog before logging out
              bool? shouldLogout = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Confirm Logout',
                        style: TextStyle(fontFamily: 'metropolis')),
                    content: const Text('Are you sure you want to log out?',
                        style: TextStyle(fontFamily: 'metropolis')),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false); // Cancel
                        },
                        child: const Text('Cancel',
                            style: TextStyle(fontFamily: 'metropolis')),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(true); // Confirm
                        },
                        child: const Text('Log Out',
                            style: TextStyle(fontFamily: 'metropolis')),
                      ),
                    ],
                  );
                },
              );

              // Proceed with logout if confirmed
              if (shouldLogout ?? false) {
                await signOut(context); // Call the logout method with context
              }
            },
            icon: const Icon(Icons.exit_to_app),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Text(
              'Welcome to the Admin Panel',
              style: TextStyle(
                fontSize: 24,
                fontFamily: 'metropolis',
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text("Upload Main Stream Podcasts",style: TextStyle(
                fontSize: 22,
                fontFamily: 'metropolis',
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),),
            const SizedBox(height: 5),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UploadPage()),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Ink(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                decoration: BoxDecoration(
                  color: Colors.teal,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Upload Podcasts',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'metropolis',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
             const SizedBox(height: 24),
            const Divider(thickness: 1,),
             const SizedBox(height: 24),
            const Text("Upload Featured Podcasts and Theme Audios ",style: TextStyle(
                fontSize: 22,
                fontFamily: 'metropolis',
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),),
            const SizedBox(height: 5),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PodcastAdminPage()),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Ink(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                decoration: BoxDecoration(
                  color: Colors.teal,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Featured Tab',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'metropolis',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(thickness: 1,),
             const SizedBox(height: 24),
            const Text("Upload sliders or New updates and posters ",style: TextStyle(
                fontSize: 22,
                fontFamily: 'metropolis',
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),),
            const SizedBox(height: 5),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SliderImageUploadPage()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent,
                foregroundColor: Colors.teal,
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Upload Sliders',
                  style: TextStyle(
                    fontFamily: 'metropolis',
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                    fontSize: 18
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
