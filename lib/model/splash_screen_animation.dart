import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:arasu_fm/main.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return  AnimatedSplashScreen(splash: 
    Center(
      child: Column(children: 
      [const Text("Arasu FM 90.4 MHz",style: TextStyle(fontFamily: "metropolis",fontSize: 26,fontWeight: FontWeight.bold,color: Colors.white),),
      const Text("Kumbakonam",style: TextStyle(fontFamily: "metropolis",fontSize: 20,fontWeight: FontWeight.bold,color: Color.fromARGB(137, 255, 255, 255)),),
      const SizedBox(height: 30,),
      Center( child: Lottie.asset("assets/splash.json"),),
      const Spacer(),
      const Text("Developed by",style: TextStyle(fontFamily: "metropolis", color: Colors.grey),),
      const Text("NightSpace Technologies",style: TextStyle(fontFamily: "metropolis", color: Colors.grey,fontWeight: FontWeight.bold,fontSize: 18),)],),
    ),
     nextScreen: const AuthWrapper(),
     splashIconSize: 600,backgroundColor:
       const Color.fromARGB(255, 2, 15, 27),);
  
  
  }
}