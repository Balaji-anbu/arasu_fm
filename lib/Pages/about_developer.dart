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

  const AboutDeveloperPage({super.key});

  // Method to launch a URL
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication, // or LaunchMode.inAppWebView
    )) {
      throw Exception('Could not launch $url');
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
      backgroundColor: Colors.transparent, // Make Scaffold's background transparent
      body: Stack(
        children: [
          // Background Image as Scaffold background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/back.jpg'), // Your background image here
                  fit: BoxFit.cover, // Ensures the image covers the entire screen
                ),
              ),
            ),
          ),
          // Semi-transparent overlay for better contrast
          Positioned.fill(
            child: Container(
              color: Colors.black.withAlpha((0.6 * 255).round()), // Dark overlay for text contrast
            ),
          ),
          // Content
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Pushes content to top and bottom
            children: [
              // Top content
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column( mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 100),
                      Text(
                        'Balaji A',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Flutter Developer',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 20),
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
                      const SizedBox(height: 20),
                      Text(
                        'Passionate about creating seamless, user-friendly mobile applications with modern UI/UX and efficient architecture.',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[300],
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              // Spacer to push "Get In Touch" to the bottom
              const Spacer(),
              // Bottom content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
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
                    const SizedBox(height: 12,),
                    const Text("NightSpace Technologies",style: TextStyle(color: Colors.grey,fontFamily: "metropolis",))
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
