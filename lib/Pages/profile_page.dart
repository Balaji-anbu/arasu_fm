import 'package:arasu_fm/Pages/about_developer.dart';
import 'package:arasu_fm/Pages/about_fm.dart';
import 'package:arasu_fm/Pages/bug_report.dart';
import 'package:arasu_fm/Pages/fm_team.dart';
import 'package:arasu_fm/Pages/onboarding.dart';
import 'package:arasu_fm/model/share_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

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
    currentUser = _auth.currentUser; // Get the current user
  }

  Future<void> logout() async {
    try {
      if (currentUser != null) {
        for (var provider in currentUser!.providerData) {
          if (provider.providerId == 'google.com') {
            // Logout from Google
            final GoogleSignIn googleSignIn = GoogleSignIn();
            await googleSignIn.signOut();
            print('Google user logged out');
          }
        }
      }

      // Sign out from FirebaseAuth
      await _auth.signOut();
      print('Firebase user logged out');

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => Onboarding()));
    } catch (e) {
      print('Error during logout: $e');
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
      return doc['link'];
    } catch (e) {
      print('Error fetching website link: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 2, 15, 27),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            expandedHeight: size.height * 0.4,
            collapsedHeight: size.height * 0.2 < kToolbarHeight
                ? kToolbarHeight
                : size.height * 0.2,
            floating: true,
            pinned: true,
            backgroundColor: const Color.fromARGB(255, 2, 15, 27),
            flexibleSpace: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                double maxExtent = constraints.maxHeight;
                double minExtent = kToolbarHeight;
                double collapseFactor =
                    (maxExtent - minExtent) / (size.height * 0.4 - minExtent);

                double profileSize = 150 * collapseFactor.clamp(0, 1);
                double profileTop = (maxExtent / 2 - profileSize / 2) *
                    collapseFactor.clamp(0.4, 1);
                double profileLeft = collapseFactor == 1
                    ? size.width / 2 - profileSize / 2
                    : 16.0;

                double titleOpacity = collapseFactor.clamp(1, 1);
                double titleLeft = collapseFactor == 1
                    ? size.width / 2 - profileSize / 2
                    : profileLeft + profileSize + 20;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration:
                          const BoxDecoration(color: Colors.transparent),
                    ),
                    // Profile Image
                    Positioned(
                      top: profileTop + (collapseFactor == 1 ? 0 : 50.0),
                      left: profileLeft,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: profileSize,
                        height: profileSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.0),
                          image: DecorationImage(
                            image: NetworkImage(
                              currentUser?.photoURL ??
                                  'https://via.placeholder.com/150', // Fallback image
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    // Title Text
                    Positioned(
                      top: profileTop + profileSize / 2 + 37,
                      left: titleLeft,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: titleOpacity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              currentUser?.displayName ?? 'No Name',
                              style: TextStyle(
                                fontSize: size.width * 0.05,
                                fontFamily: 'metropolis',
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
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
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.greenAccent,
                          fontFamily: 'metropolis',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Divider(height: 32),
                      const SizedBox(height: 15),
                      ..._buildListItems(),
                      const Divider(height: 32),
                      ListTile(
                        title: const Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 18,
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
                          // Show confirmation dialog before logging out
                          bool? shouldLogout = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                backgroundColor: Colors.grey[900],
                                title: const Text(
                                  'Confirm Logout',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'metropolis'),
                                ),
                                content: const Text(
                                  'Are you sure you want to log out?',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'metropolis'),
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {
                                      // Close the dialog and return false (user canceled)
                                      Navigator.of(context).pop(false);
                                    },
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'metropolis'),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      // Close the dialog and return true (user confirmed)
                                      Navigator.of(context).pop(true);
                                    },
                                    child: const Text(
                                      'Logout',
                                      style: TextStyle(
                                          color: Colors.red,
                                          fontFamily: 'metropolis'),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );

                          // If user confirmed, call the logout function
                          if (shouldLogout == true) {
                            await logout(); // Call your logout function
                          }
                        },
                      ),
                      SizedBox(height: 130),
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

  List<Widget> _buildListItems() {
    return [
      _buildListTile('Visit Website', Icons.web_asset, () async {
        String? url = await _getWebsiteLink();
        if (url != null) {
          if (await canLaunch(url)) {
            await launch(url);
          } else {
            throw 'Could not launch $url';
          }
        }
      }),
      _buildListTile('About FM', Icons.info, () {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => AboutPage()));
      }),
      _buildListTile('Our Team', Icons.people, () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => TeamMembersPage()));
      }),
      _buildListTile('About Developer', Icons.developer_mode_outlined, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AboutDeveloperPage()),
        );
      }),
      _buildListTile('Share App', Icons.share, () {
        // Create an instance of ShareAppButton and show it in a dialog or navigate to a new screen, for example:
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.grey.shade900,
              title: Text(
                'Share App',
                style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'metropolis',
                    fontWeight: FontWeight.bold),
              ),
              actions: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment
                      .center, // Align items at the end of the row
                  children: [
                    Text(
                      'Tap Here...',
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'metropolis',
                          fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.share,
                        color: Colors.greenAccent,
                      ), // Your icon here
                      onPressed: () {
                        // Handle icon button press
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
      _buildListTile('Report Bug', Icons.bug_report, () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => BugReportingPage()));
      }),
    ];
  }

  Widget _buildListTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          color: Colors.white,
          fontFamily: 'metropolis',
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: Icon(icon, color: Colors.white),
      onTap: onTap,
    );
  }
}
