import 'package:arasu_fm/AdminPages/admin_home.dart';
import 'package:arasu_fm/Pages/home_page.dart';
import 'package:arasu_fm/Pages/onboarding.dart';
import 'package:arasu_fm/Pages/video_page.dart';
import 'package:arasu_fm/Providers/audio_provider.dart';
import 'package:arasu_fm/controllers/login_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => VideoProvider(
            apiKey: 'AIzaSyBEj56vz8MecSel7FKQaHN2roQ1fWX2Cug',
            channelId: 'UCdm4VTNKBzjVw0K37YCiKiA',
          ),
        ),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(create: (_) => LoginController()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: Lottie.asset('assets/loading.json')),
          );
        }
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            final user = snapshot.data;
            print('User data: ${snapshot.data}');
            print('User email: ${user?.email}');

            if (user != null &&
                user.email != null &&
                user.email?.toLowerCase() == 'anbubalaji2112@gmail.com') {
              return AdminHome();
            } else {
              return const HomePage();
            }
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return const Onboarding();
          }
        } else {
          return Center(
            child: Lottie.asset('assets/loading.json'),
          );
        }
      },
    );
  }
}
