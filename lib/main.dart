import 'package:arasu_fm/AdminPages/admin_home.dart';
import 'package:arasu_fm/Pages/home_page.dart';
import 'package:arasu_fm/Pages/onboarding.dart';
import 'package:arasu_fm/Providers/audio_provider.dart';
import 'package:arasu_fm/Providers/video_provider.dart';
import 'package:arasu_fm/controllers/login_controller.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:lottie/lottie.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';


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
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
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
  DateTime? lastPressedTime;
  bool isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkInternetConnection();
    // Add listener for connectivity changes
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results.first); // Use the first result
    });
  }

  // Method to check internet connection
  Future<void> _checkInternetConnection() async {
    final results = await Connectivity().checkConnectivity();
    _updateConnectionStatus(results.first); // Use the first result
  }

  // Update connection status
  void _updateConnectionStatus(ConnectivityResult result) {
    setState(() {
      isOffline = result == ConnectivityResult.none;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        DateTime now = DateTime.now();
        if (lastPressedTime == null || now.difference(lastPressedTime!) > Duration(seconds: 2)) {
          lastPressedTime = now;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Do That Again! To Exit.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ));
          return false;
        } else {
          SystemNavigator.pop();
          return true;
        }
      },
      child: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (isOffline) {
            return const NoInternetPage();
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(backgroundColor: Color.fromARGB(255, 2, 15, 27),
              body: Center(child: Lottie.asset('assets/loading.json')),
            );
          }

          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) {
              final user = snapshot.data;
              if (user != null && user.email == 'arasucrs2025@aec.org.in') {
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
      ),
    );
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
            SizedBox(height: 20),
            Text(
              'No Internet Connection!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,fontFamily:"metropolis",color: Colors.red),
            ),
            SizedBox(height: 10),
            Text(
              'Please Check Your Internet Settings And Try Again',
              style: TextStyle(fontSize: 14,fontFamily: "metropolis",color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
