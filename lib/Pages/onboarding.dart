import 'package:arasu_fm/Pages/Email_password.dart';
import 'package:arasu_fm/Pages/login.dart';
import 'package:arasu_fm/main.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Onboarding extends StatelessWidget {
  const Onboarding({super.key});

  Future<User?> _signInWithGoogle(BuildContext context) async {
    try {
      // Initiating Google sign-in
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();

      if (googleSignInAccount == null) {
        // The user canceled the sign-in
        print('Google sign-in was aborted.');
        return null;
      }

      // Obtain the Google authentication credentials
      final GoogleSignInAuthentication googleAuth =
          await googleSignInAccount.authentication;

      // Create a new Firebase credential using the obtained Google token
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with Firebase using the Google credentials
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // User is now authenticated with Firebase
        print('Google sign-in successful: ${user.displayName}, ${user.email}');
        return user; // Return the Firebase user
      } else {
        print('Failed to sign in with Google.');
        return null;
      }
    } catch (e) {
      print('Error during Google sign-in: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xff213555),
              Color.fromARGB(255, 2, 15, 27),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: screenHeight * 0.3),
                  const Text(
                    'Arasu Community Radio',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Metropolis',
                        letterSpacing: 2),
                  ),
                  const Text(
                    '90.4 MHz',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Metropolis',
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.05),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const EmailPassword()));
                    },
                    splashColor: Colors.black26,
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.015,
                          horizontal: screenWidth * 0.1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1ED760),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: Colors.black, width: 0.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.email),
                            SizedBox(width: screenWidth * 0.02),
                            const Text(
                              'Continue With Email',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 17,
                                  fontFamily: 'Metropolis',
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  InkWell(
                    onTap: () async {
                      final user = await _signInWithGoogle(context);

                      if (user != null) {
                        // If user is successfully authenticated, navigate to HomePage
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AuthWrapper()),
                        );
                      } else {
                        // Handle failure (optional)
                        print('Google sign-in failed.');
                      }
                    },
                    splashColor: Colors.white24,
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.015,
                          horizontal: screenWidth * 0.02,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white, width: 0.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              "assets/google.png",
                              width: screenWidth * 0.08,
                              height: screenHeight * 0.04,
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            const Text(
                              ' Continue with Google',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Metropolis',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account?',
                        style: TextStyle(
                            color: Colors.white, fontFamily: 'metropolis'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginPage()));
                        },
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Metropolis',
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
