import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:arasu_fm/main.dart';
import 'package:arasu_fm/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedSplashScreen(
        splash: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Arasu FM 90.4 MHz",
                      style: TextStyle(
                        fontFamily: "metropolis",
                        fontSize: constraints.maxWidth > 600 ? 36 : 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      "Kumbakonam",
                      style: TextStyle(
                        fontFamily: "metropolis",
                        fontSize: constraints.maxWidth > 600 ? 28 : 20,
                        fontWeight: FontWeight.bold,
                        color:AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: constraints.maxHeight * 0.05),
                    Center(
                      child: SizedBox(
                        width: constraints.maxWidth > 600 
                            ? constraints.maxWidth * 0.5 
                            : constraints.maxWidth * 0.8,
                        child: Lottie.asset(
                          "assets/splash.json",
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    SizedBox(height: constraints.maxHeight * 0.2),
                     Text(
                      "Developed by",
                      style: TextStyle(
                        fontFamily: "metropolis", 
                        color: AppColors.textSecondary,
                         fontSize: constraints.maxWidth > 600 ? 16 : 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      "NightSpace Technologies",
                      style: TextStyle(
                        fontFamily: "metropolis", 
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: constraints.maxWidth > 600 ? 20 : 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        nextScreen: const AuthWrapper(),
        splashIconSize: 800,
        backgroundColor: AppColors.primary,
      ),
    );
  }
}