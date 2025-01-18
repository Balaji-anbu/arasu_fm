import 'dart:async';
import 'package:arasu_fm/AdminPages/admin_home.dart';
import 'package:arasu_fm/Pages/home_page.dart';
import 'package:arasu_fm/Pages/onboarding.dart';
import 'package:arasu_fm/Providers/audio_provider.dart';
import 'package:arasu_fm/Providers/video_provider.dart';
import 'package:arasu_fm/controllers/login_controller.dart';
import 'package:arasu_fm/model/splash_screen_animation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:lottie/lottie.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("43dcbfa9-f88c-41ce-aa91-8b13eefbbd81");
  OneSignal.Notifications.requestPermission(true);
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
            apiKeys: [
              'AIzaSyD-vzZytRgrxBKPa-vZCklh7jhQlOLKQ9c',
              'AIzaSyBEj56vz8MecSel7FKQaHN2roQ1fWX2Cug',
              'AIzaSyAVujyv2YYooGXfU569pdpUShfdacI5UaM',
              'AIzaSyD4WBaJKHyiPr_kEquWy9k2Sef-2m0RvHQ',
              'AIzaSyBNjFAWgXSHo2M0x0_kMyXnlfCk3wpH8Ls',
              'AIzaSyAxBdQUi4WlO2NCfyE6pUrXyy1er38OIwQ',
              'AIzaSyCto6HG50BqJgEwZkyfAEKHCXkvazcMa0I',
              'AIzaSyAMPn9XVPddbVSxDFQCVTKAZzXGouj43rk',
              'AIzaSyD0sUvYLGmBVA9AUALJerlL_N_AMLKSvHs',
              'AIzaSyALPVfniig5lqcKoXYa8jRcaV8bh6Gwi5I',
            ],
            channelId: 'UCdm4VTNKBzjVw0K37YCiKiA',
          ),
        ),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(create: (_) => LoginController()),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}
class _AuthWrapperState extends State<AuthWrapper> {
  DateTime? lastPressedTime; // Track last back button press time
  bool isOffline = false;
  bool isInitializing = true;
  User? user;

  late InternetConnectionChecker connectionChecker;

  @override
  void initState() {
    super.initState();
    connectionChecker = InternetConnectionChecker.createInstance();

    // Initial internet check only at startup
    _checkInternetConnection();

    // Handle Firebase auth state only once during startup
    _initializeAuthState();
  }

  // Method to check internet connection once during startup
  Future<void> _checkInternetConnection() async {
    bool isConnected = await connectionChecker.hasConnection;
    _updateConnectionStatus(isConnected);
  }

  // Update connection status
  void _updateConnectionStatus(bool isConnected) {
    setState(() {
      isOffline = !isConnected;
    });
  }

  // Method to handle Firebase auth state initialization
  Future<void> _initializeAuthState() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      // Set the user and stop initializing
      setState(() {
        user = currentUser;
        isInitializing = false;
      });
    } catch (e) {
      // Handle errors during auth state initialization
      setState(() {
        isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Intercept the back button using WillPopScope
    return WillPopScope(
      onWillPop: () async {
        // Handle double-tap or Snackbar for exit
        DateTime now = DateTime.now();
        if (lastPressedTime == null ||
            now.difference(lastPressedTime!) > const Duration(seconds: 1)) {
          lastPressedTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Press back again to exit'),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return false; // Prevent exiting the app
        }
        return true; // Allow exiting the app
      },
      child: _buildMainContent(context),
    );
  }

  // Separate function to build the main content
  Widget _buildMainContent(BuildContext context) {
    // If offline at startup, show no internet page
    if (isOffline && isInitializing) {
      return const NoInternetPage();
    }

    // Only show loading on initial app launch
    if (isInitializing) {
      return const Scaffold(
        backgroundColor: Color.fromARGB(255, 2, 15, 27),
        body: Center(
          child: Text(
            'Loading...',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: "metropolis",
            ),
          ),
        ),
      );
    }

    // After initialization, check if the user is logged in
    if (user != null) {
      if (user?.email == 'arasucrs2025@aec.org.in') {
        return AdminHome();
      } else {
        return const HomePage();
      }
    } else {
      return const Onboarding();
    }
  }
}

class NoInternetPage extends StatelessWidget {
  const NoInternetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: const Color.fromARGB(255, 2, 15, 27),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/404.json', width: 300, height: 350),
            const SizedBox(height: 20),
            const Text(
              'No Internet Connection!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,fontFamily:"metropolis",color: Colors.red),
            ),
            const SizedBox(height: 10),
            const Text(
              'Please Check Your Internet Settings And Try Again',
              style: TextStyle(fontSize: 14,fontFamily: "metropolis",color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}  