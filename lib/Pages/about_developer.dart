import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutDeveloperPage extends StatelessWidget {
  // Replace these with your actual URLs and email
  final String linkedInUrl =
      'https://www.linkedin.com/in/balaji-anbu-473a58273';
  final String instagramUrl = 'https://www.instagram.com/___balaji___22';
  final String githubUrl = 'https://github.com/Balaji-anbu';
  final String email = 'anbubalaji2112@gmail.com';

  // Method to launch a URL
  Future<void> _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _openGmailApp(String email) async {
    final Uri gmailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: '', // Add additional fields like subject/body if needed
    );

    if (await canLaunchUrl(gmailUri)) {
      await launchUrl(gmailUri);
    } else {
      throw 'Gmail app is not installed or could not open.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/back.jpg', // Add your background image here
              fit: BoxFit.cover,
            ),
          ),
          // Semi-transparent overlay for better contrast
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.6),
            ),
          ),
          // Content
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 20),
                  SizedBox(height: 100),
                  Text(
                    'Balaji A',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Flutter Developer',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Final Year CSE Department',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[400],
                    ),
                  ),
                  Text(
                    'Arasu Engineering College',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[400],
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Passionate about creating seamless, user-friendly mobile applications with modern UI/UX and efficient architecture.',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[300],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 100),
                  Text(
                    'Get In Touch ',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'metropolis',
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Image.asset(
                          'assets/linkedin.png',
                          height: 50,
                          width: 50,
                        ),
                        iconSize: 30,
                        onPressed: () => _launchUrl(linkedInUrl),
                      ),
                      IconButton(
                        icon: Image.asset(
                          'assets/instagram.png',
                          height: 50,
                          width: 50,
                        ),
                        iconSize: 30,
                        onPressed: () => _launchUrl(instagramUrl),
                      ),
                      IconButton(
                        icon: Image.asset(
                          'assets/github.png',
                          height: 50,
                          width: 50,
                        ),
                        iconSize: 30,
                        onPressed: () => _launchUrl(githubUrl),
                      ),
                      IconButton(
                        icon: Image.asset(
                          'assets/mail.png',
                          height: 48,
                          width: 45,
                        ),
                        iconSize: 30,
                        onPressed: () => _openGmailApp(email),
                      ),
                    ],
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
