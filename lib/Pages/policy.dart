import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PolicyPage extends StatelessWidget {
  const PolicyPage({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Terms and Policies', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 2, 15, 27),
      ),
      backgroundColor: const Color.fromARGB(255, 2, 15, 27),
      body: ListView(
        children: [
          ListTile(
            title: const Text(
              'Privacy Policy',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'metropolis',
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: const Icon(Icons.privacy_tip, color: Colors.white),
            onTap: () => _launchUrl('https://fluffy-syrniki-7d133d.netlify.app/'),
          ),
          Divider(thickness: 0.1, color: Colors.white),
          ListTile(
            title: const Text(
              'Terms and Conditions',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'metropolis',
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: const Icon(Icons.description, color: Colors.white),
            onTap: () => _launchUrl('https://app.websitepolicies.com/policies/view/yx35d2ql'),
          ),
          Divider(thickness: 0.1, color: Colors.white),
          SizedBox(height: 20,),
          Text(
            'App Version: 1.0.0',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'metropolis',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
