import 'package:arasu_fm/theme/colors.dart';
import 'package:flutter/material.dart';

class TeamMembersPage extends StatelessWidget {
  final List<Map<String, String>> teamMembers = [
    {
      'name': 'Dr. T. Balamurugan',
      'position': 'Director',
      'image': 'assets/balamurugan.jpeg'
    },
    {
      'name': 'Dr. R. Vijayaragavan',
      'position': 'Station Manager & \n Programme Co-ordinator',
      'image': 'assets/vijayaragavan.jpeg'
    },
    {
      'name': 'Mr. G. Venkatraman',
      'position': 'Editor',
      'image': 'assets/venkatraman.jpeg'
    },
    {
      'name': 'Mrs. M. Nivedha',
      'position': 'Radio Jockey',
      'image': 'assets/nivedha.jpeg'
    },
    {
      'name': 'Mr. R. Karthikeyan',
      'position': 'Sound Engineer',
      'image': 'assets/karthikeyan.jpeg'
    },
     {
      'name': 'Mr. S. Kannan',
      'position': 'maintenance Engineer',
      'image': 'assets/kannan.jpeg'
    },
    
    {
      'name': 'Ms. P. Monisha',
      'position': 'Radio Jockey',
      'image': 'assets/monisha.jpeg'
    },
     {
      'name': 'Dr. K. Kalpana',
      'position': 'Radio jockey',
      'image': 'assets/Kalpana.jpg'
    },
    {
      'name': 'Mrs. V. Muthumeenakshi',
      'position': 'Broadcast Engineer',
      'image': 'assets/Muthumeenakshi.jpg'
    },
     {
      'name': 'Mrs. A. Vinodhini',
      'position': 'Station Supporting Member',
      'image': 'assets/vinodhini.jpeg'
    },
    {
      'name': 'Dr. P. Iyyappan',
      'position': 'Station Supporting Member',
      'image': 'assets/iyyappan.jpeg'
    },
   
    {
      'name': 'Ms. S. Vishnupriya ',
      'position': 'Station Supporting Member',
      'image': 'assets/Vishnupriya.jpg'
    },

       

    
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
             AppColors.secondary,
              AppColors.primary,
            ],
          ),
        ),
        child: Column(
          children: [
            AppBar(
              iconTheme: const IconThemeData(color: Colors.white),
              title: const Text(
                ' Our Team Members',
                style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'metropolis',
                    fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                  ),
                  itemCount: teamMembers.length,
                  itemBuilder: (context, index) {
                    final member = teamMembers[index];
                    return TeamMemberCard(
                      name: member['name']!,
                      position: member['position']!,
                      image: member['image']!,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TeamMemberCard extends StatelessWidget {
  final String name;
  final String position;
  final String image;

  const TeamMemberCard({
    required this.name,
    required this.position,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 5,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue,
              Colors.purple,
            ],
          ),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 100.0,
              backgroundImage: AssetImage(image),
            ),
            const SizedBox(height: 8.0),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'metropolis',
                fontSize: 18.0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4.0),
            Text(
              position,
              style: TextStyle(
                fontSize: 16.0,
                fontFamily: 'metropolis',
                color: Colors.grey.shade300,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
