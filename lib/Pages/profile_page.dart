import 'package:arasu_fm/Pages/about_developer.dart';
import 'package:arasu_fm/Pages/about_fm.dart';
import 'package:arasu_fm/Pages/bug_report.dart';
import 'package:arasu_fm/Pages/fm_team.dart';
import 'package:arasu_fm/Pages/onboarding.dart';
import 'package:arasu_fm/Providers/audio_provider.dart';
import 'package:arasu_fm/model/share_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
  }

  Future<void> logout() async {
    try {
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);
      if (audioProvider.isPlaying) {
        await audioProvider.audioPlayer.stop();
      }

      if (currentUser != null) {
        for (var provider in currentUser!.providerData) {
          if (provider.providerId == 'google.com') {
            final GoogleSignIn googleSignIn = GoogleSignIn();
            await googleSignIn.signOut();
          }
        }
      }

      await _auth.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Onboarding()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during logout: $e'),
        ),
      );
    }
  }

  Future<String?> _getWebsiteLink() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('weblink')
          .doc('finallink')
          .get();
      String? url = doc['link'];
      return url;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final toolbarHeight = size.height * 0.2;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 2, 15, 27),
      body: Column(
        children: [
          Center(
            child: Container(
              height: toolbarHeight,
              color: const Color.fromARGB(255, 2, 15, 27),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 85,
                    height: 85,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.0),
                    ),
                    child: currentUser?.photoURL != null &&
                            currentUser!.photoURL!.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              currentUser!.photoURL!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _fallbackAvatar();
                              },
                            ),
                          )
                        : _fallbackAvatar(),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 1),
                            const Text(
                              'Signed in with',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontFamily: 'metropolis',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              currentUser?.email ?? 'No Email',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.greenAccent,
                                fontFamily: 'metropolis',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(height: 32),
                            ..._buildListItems(),
                            const Divider(height: 32),
                            ListTile(
                              title: const Text(
                                'Report Bug',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.red,
                                  fontFamily: 'metropolis',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              leading: const Icon(
                                Icons.bug_report,
                                color: Colors.red,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                           BugReportingPage()),
                                );
                              },
                            ),
                            ListTile(
                              title: const Text(
                                'Logout',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.red,
                                  fontFamily: 'metropolis',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              leading: const Icon(
                                Icons.exit_to_app,
                                color: Colors.red,
                              ),
                              onTap: () async {
                                bool? shouldLogout = await showDialog<bool>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      backgroundColor: Colors.grey[900],
                                      title: const Text(
                                        'Confirm Logout',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      content: const Text(
                                        'Are you sure you want to log out?',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text(
                                            'Cancel',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          child: const Text(
                                            'Logout',
                                            style:
                                                TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                if (shouldLogout == true) {
                                  await logout();
                                }
                              },
                            ),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "App Version : 1.0.0",
                                  style: TextStyle(
                                      color: Colors.grey,
                                      fontFamily: "metropolis"),
                                ),
                              ],
                            ),
                            const SizedBox(height: 130),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackAvatar() {
    String initials = currentUser?.email?.substring(0, 1).toUpperCase() ?? "?";
    return CircleAvatar(
      backgroundColor: Colors.blueAccent,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  List<Widget> _buildListItems() {
    return [
    _buildListTile('Visit Website', Icons.web_asset, Colors.grey, () async {
  try {
    String? url = await _getWebsiteLink(); // Fetch the website link
    if (url != null && url.isNotEmpty) {
      await launch(
        url,
        
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Website link not found.')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error launching website: $e')),
    );
  }
}),

      _buildListTile('About FM', Icons.info, Colors.grey, () {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => AboutPage()));
      }),
      _buildListTile('Our Team', Icons.people, Colors.grey, () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) =>  TeamMembersPage()));
      }),
      _buildListTile(
          'About Developer', Icons.developer_mode_outlined, Colors.grey, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) =>  AboutDeveloperPage()),
        );
      }),
      _buildListTile('Share App', Icons.share, Colors.grey, () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.grey.shade900,
              title: const Text(
                'Share App',
                style: TextStyle(color: Colors.white),
              ),
              actions: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Tap Here...',
                      style: TextStyle(color: Colors.white),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.share,
                        color: Colors.greenAccent,
                      ),
                      onPressed: () {
                        ShareAppButton().shareApp();
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        );
      }),
    ];
  }

  Widget _buildListTile(
      String title, IconData icon, Color iconColor, VoidCallback onTap) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontFamily: 'metropolis',
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: Icon(icon, color: iconColor),
      onTap: onTap,
    );
  }
}
