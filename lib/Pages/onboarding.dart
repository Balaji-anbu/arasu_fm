
import 'package:arasu_fm/Pages/sign_in_page.dart';
import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';

class Onboarding extends StatelessWidget {
  const Onboarding({super.key});

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      globalBackgroundColor: const Color.fromARGB(255, 2, 15, 27),
      pages: [
        PageViewModel(
          title: "Welcome to Arasu FM",
          body: "Experience the best community radio with Arasu FM 90.4 MHz.",
          image: Center(child: Icon(Icons.radio_outlined, size: 100, color: Colors.blue)),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Metropolis',
            ),
            bodyTextStyle: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontFamily: 'Metropolis',
            ),
            pageColor: Color.fromARGB(255, 2, 15, 27),
          ),
        ),
        PageViewModel(
          title: "Stay Connected",
          body: "Listen to knowledgable programs and stay connected with the world.",
          image: Center(child: Icon(Icons.wifi, size: 100, color: Colors.blue)),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Metropolis',
            ),
            bodyTextStyle: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontFamily: 'Metropolis',
            ),
            pageColor: Color.fromARGB(255, 2, 15, 27),
          ),
        ),
        PageViewModel(
          title: "Join Our Community",
          body: "Be a part of our community and make the society a better place.",
          image: Center(child: Icon(Icons.people, size: 100, color: Colors.blue)),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Metropolis',
            ),
            bodyTextStyle: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontFamily: 'Metropolis',
            ),
            pageColor: Color.fromARGB(255, 2, 15, 27),
          ),
        ),
      ],
      onDone: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignInPage()),
        );
      },
      
      
      
      next: const Icon(Icons.double_arrow, color: Colors.blue),
      done: const Text("Lets Go!", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
      dotsDecorator: const DotsDecorator(
        activeColor: Colors.blue,
        size: Size(10.0, 10.0),
        color: Colors.white,
        activeSize: Size(22.0, 10.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(30.0)),
        ),
      ),
    );
  }
}
