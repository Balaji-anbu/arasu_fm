import 'package:arasu_fm/Pages/Email_password.dart';
import 'package:arasu_fm/Pages/login.dart';
import 'package:arasu_fm/main.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  Future<User?> _signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();

      if (googleSignInAccount == null) {
        print('Google sign-in was aborted.');
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleSignInAccount.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        print('Google sign-in successful: ${user.displayName}, ${user.email}');
        return user;
      } else {
        print('Failed to sign in with Google.');
        return null;
      }
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during Google sign-in: ${e.message}');
      return null;
    } catch (e) {
      print('Error during Google sign-in: $e');
      return null;
    }
  }


  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }


  @override
  Widget build(BuildContext context) {
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
                  SizedBox(height: screenHeight * 0.01),
                  Image.asset(
                    'assets/FM_logo.png',
                    width: screenWidth * 0.5,
                    height: screenHeight * 0.2,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    'Arasu Community Radio',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Metropolis',
                      letterSpacing: screenWidth * 0.004,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    '90.4 MHz',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.055,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Metropolis',
                      height: 1.2,
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
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AuthWrapper()),
                        );
                      } else {
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
                  SizedBox(height: screenHeight * 0.01),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'metropolis',
                          fontSize: screenWidth * 0.035,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginPage()));
                        },
                        child: Text(
                          'Login',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Metropolis',
                            fontSize: screenWidth * 0.04,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.1),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                    child: Center(
                      child: Text.rich(
                        TextSpan(
                          text: 'By continuing, you agree to our ',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: screenWidth * 0.033,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => _launchURL('https://app.websitepolicies.com/policies/view/yx35d2ql'),
                                child: const Text(
                                  'Terms of Service',
                                  style: TextStyle(
                                    color: Colors.blueAccent,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const TextSpan(text: ' and '),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => _launchURL('https://fluffy-syrniki-7d133d.netlify.app/'),
                                child: const Text(
                                  'Privacy Policy',
                                  style: TextStyle(
                                    color: Colors.blueAccent,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
