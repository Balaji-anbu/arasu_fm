import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'About us',
          style: TextStyle(
              color: Colors.white,
              fontFamily: 'metropolis',
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.grey[900],
      ),
      body: Container(
        color: Colors.black, // Dark background
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionCard(
                title: 'Welcome to Arasu FM 90.4 MHz!',
                content:
                    'Arasu FM is a Community Radio initiative operated under the auspices of Arasu Engineering College, Kumbakonam, with permission from the Government of India, Ministry of Information & Broadcasting. We are dedicated to serving our local community with a vibrant mix of informative and entertaining programming.',
              ),
              SectionCard(
                title: 'Broadcast Details',
                content:
                    'Frequency: 90.4 MHz\nRegular Broadcast: 9:30 AM to 11:30 PM\nRe-broadcast: 11:35 AM to 2:35 PM\nLanguages: Tamil, with select programs in English',
              ),
              SectionCard(
                title: 'Our Programming',
                content:
                    'Our carefully curated programs span diverse categories designed to inform, educate, and entertain. These include:\n\n'
                    '- Tamil Language & Culture\n'
                    '- Health Awareness\n'
                    '- Science and Inventions\n'
                    '- History\n'
                    '- Book Reviews\n'
                    '- Motivational Speeches\n'
                    '- Other Language Awareness (English)\n'
                    '- Elocution\n'
                    '- Kids’ Time\n'
                    '- Music Zone\n'
                    '- Agriculture\n'
                    '- Interviews with professionals\n'
                    '- Live Programs\n'
                    '- Community Awareness Initiatives',
              ),
              SectionCard(
                title: 'Our Vision',
                content:
                    'To educate the public, raise awareness, protect health and the environment, and enhance civic and cultural life in our communities while providing a reliable and vital source of information.',
              ),
              SectionCard(
                title: 'Our Mission',
                content:
                    'Achieving community awareness and education through engaging content, effective broadcast strategies, and connecting with our listeners to foster knowledge, motivation, and empowerment.',
              ),
              SectionCard(
                title: 'Contact Us',
                content:
                    'Address: Arasu FM 90.4 MHz\nArasu Engineering College\nChennai Main Road, Kumbakonam – 612501\nThanjavur District, Tamil Nadu\n\n'
                    'Landline: 0435 – 2777777-82\nEmail: arasufm@aec.org.in, arasuengg@aec.org.in\n\n'
                    'Station Manager: Dr. R. Vijayaragavan\nPhone: +91 75981 87104',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final String title;
  final String content;

  SectionCard({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900], // Light color card for contrast
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontFamily: 'Metropolis',
                fontWeight: FontWeight.bold,
                color: Colors.greenAccent,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'metropolis',
                color: Colors.white,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
