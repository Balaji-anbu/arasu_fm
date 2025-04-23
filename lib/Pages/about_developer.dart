import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class AboutDeveloperPage extends StatefulWidget {
  // Replace these with your actual URLs and email
  final String linkedInUrl =
      'https://www.linkedin.com/in/balaji-anbu-473a58273';
  final String instagramUrl = 'https://www.instagram.com/___balaji___22';
  final String githubUrl = 'https://github.com/Balaji-anbu';
  final String email = 'anbubalaji2112@gmail.com';

  const AboutDeveloperPage({super.key});

  @override
  State<AboutDeveloperPage> createState() => _AboutDeveloperPageState();
}

class _AboutDeveloperPageState extends State<AboutDeveloperPage>
    with SingleTickerProviderStateMixin {
  // Animation controller
  late AnimationController _controller;
  
  // For floating particles effect
  final List<Particle> _particles = [];
  static const int _particleCount = 50;
  
  // Control particle animation
  bool _showFullParticleAnimation = false;
  bool _allComponentsLoaded = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    // Create background particles
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(Particle());
    }
    
    // Start with partial particle animation
    // Then enable full animation after components are loaded
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        setState(() {
          _allComponentsLoaded = true;
        });
        
        // Start showing full particle animation after components load
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _showFullParticleAnimation = true;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Method to launch a URL
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }

  // Launch email
  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: widget.email,
    );
    await launchUrl(emailLaunchUri);
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen size to make the layout responsive
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;
    final double paddingFactor = isSmallScreen ? 0.03 : 0.05;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Animated Background
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlePainter(
                  _particles, 
                  _controller.value, 
                  screenSize,
                  _showFullParticleAnimation,
                ),
                size: screenSize,
              );
            },
          ),
          
          // Background Image with parallax effect
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(seconds: 1),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Positioned.fill(
                child: Opacity(
                  opacity: value,
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: const AssetImage('assets/back.jpg'),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.7),
                          BlendMode.darken,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Main content with responsive layout
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top content with staggered animations
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: EdgeInsets.all(screenSize.width * paddingFactor),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(height: screenSize.height * 0.05),
                              
                              // Avatar with pulsating effect - responsive size
                              Container(
                                height: isSmallScreen ? 100 : 120,
                                width: isSmallScreen ? 100 : 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.5),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                  gradient: LinearGradient(
                                    colors: [Colors.blue.shade400, Colors.purple.shade500],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: isSmallScreen ? 50 : 60,
                                ),
                              )
                              .animate(onPlay: (controller) => controller.repeat())
                              .scale(
                                begin: const Offset(0.9, 0.9),
                                end: const Offset(1.1, 1.1),
                                duration: 2.seconds,
                                curve: Curves.easeInOut,
                              )
                              .then()
                              .scale(
                                begin: const Offset(1.1, 1.1),
                                end: const Offset(0.9, 0.9),
                                duration: 2.seconds,
                                curve: Curves.easeInOut,
                              ),
                              
                              SizedBox(height: screenSize.height * 0.03),
                              
                              // Name with typing animation - responsive font size
                              Text(
                                'Balaji A',
                                style: GoogleFonts.poppins(
                                  fontSize: isSmallScreen ? 28 : 32,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 1.seconds)
                              .slideY(begin: 0.3, end: 0, duration: 800.ms, curve: Curves.easeOutQuad)
                              .shimmer(delay: 400.ms, duration: 1200.ms, color: Colors.blue.shade200),
                                
                              SizedBox(height: screenSize.height * 0.01),
                              
                              // Role with slide animation - responsive font size
                              Text(
                                'Flutter Developer',
                                style: GoogleFonts.poppins(
                                  fontSize: isSmallScreen ? 18 : 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade300,
                                  letterSpacing: 1.2,
                                ),
                              )
                              .animate()
                              .fadeIn(delay: 500.ms, duration: 800.ms)
                              .slideX(begin: 0.3, end: 0, delay: 500.ms, duration: 800.ms),
                                
                              SizedBox(height: screenSize.height * 0.03),
                              
                              // Education with staggered fade animations - responsive container
                              Container(
                                width: isSmallScreen ? double.infinity : screenSize.width * 0.8,
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenSize.width * 0.05, 
                                  vertical: screenSize.height * 0.015
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.shade900.withOpacity(0.3),
                                      Colors.purple.shade900.withOpacity(0.3)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(color: Colors.blue.shade800.withOpacity(0.3), width: 1),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Final Year CSE Department',
                                      style: GoogleFonts.poppins(
                                        fontSize: isSmallScreen ? 16 : 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[300],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: screenSize.height * 0.005),
                                    Text(
                                      'Arasu Engineering College',
                                      style: GoogleFonts.poppins(
                                        fontSize: isSmallScreen ? 16 : 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[300],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                              .animate()
                              .fadeIn(delay: 800.ms, duration: 800.ms)
                              .slideY(begin: 0.2, end: 0, delay: 800.ms, duration: 800.ms),
                                
                              SizedBox(height: screenSize.height * 0.03),
                              
                              // Bio with character by character animation - responsive container
                              Container(
                                width: isSmallScreen ? double.infinity : screenSize.width * 0.8,
                                padding: EdgeInsets.all(screenSize.width * 0.05),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: Colors.white.withOpacity(0.1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.1),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Passionate about creating seamless, user-friendly mobile applications with modern UI/UX and efficient architecture.',
                                  style: GoogleFonts.poppins(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    color: Colors.grey[300],
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                              .animate()
                              .fadeIn(delay: 1200.ms, duration: 800.ms)
                              .animate(delay: 1200.ms)
                              .shimmer(duration: 1.5.seconds, color: Colors.white.withOpacity(0.5)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Bottom content with social icons animation
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(screenSize.width * 0.04),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.blue.shade900.withOpacity(0.3),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Get In Touch',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.2,
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 1600.ms, duration: 800.ms),
                          
                          SizedBox(height: screenSize.height * 0.015),
                          
                          // Responsive row of social buttons
                          isSmallScreen
                              ? Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: screenSize.width * 0.02,
                                  runSpacing: screenSize.height * 0.01,
                                  children: [
                                    _buildSocialButton(
                                      'assets/linkedin.png',
                                      () => _launchUrl(widget.linkedInUrl),
                                      delay: 1800.ms,
                                      size: screenSize.width * 0.1,
                                    ),
                                    _buildSocialButton(
                                      'assets/instagram.png',
                                      () => _launchUrl(widget.instagramUrl),
                                      delay: 2000.ms,
                                      size: screenSize.width * 0.1,
                                    ),
                                    _buildSocialButton(
                                      'assets/github.png',
                                      () => _launchUrl(widget.githubUrl),
                                      delay: 2200.ms,
                                      size: screenSize.width * 0.1,
                                    ),
                                    _buildSocialButton(
                                      'assets/mail.png',
                                      _launchEmail,
                                      delay: 2400.ms,
                                      size: screenSize.width * 0.1,
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildSocialButton(
                                      'assets/linkedin.png',
                                      () => _launchUrl(widget.linkedInUrl),
                                      delay: 1800.ms,
                                      size: 50,
                                    ),
                                    _buildSocialButton(
                                      'assets/instagram.png',
                                      () => _launchUrl(widget.instagramUrl),
                                      delay: 2000.ms,
                                      size: 50,
                                    ),
                                    _buildSocialButton(
                                      'assets/github.png',
                                      () => _launchUrl(widget.githubUrl),
                                      delay: 2200.ms,
                                      size: 50,
                                    ),
                                    _buildSocialButton(
                                      'assets/mail.png',
                                      _launchEmail,
                                      delay: 2400.ms,
                                      size: 50,
                                    ),
                                  ],
                                ),
                          
                          SizedBox(height: screenSize.height * 0.01),
                          
                          Text(
                            "NightSpace Technologies",
                            style: GoogleFonts.poppins(
                              color: Colors.grey,
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 2600.ms, duration: 800.ms),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSocialButton(
    String asset, 
    VoidCallback onPressed, 
    {required Duration delay, double? size = 50}
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: IconButton(
        icon: Image.asset(
          asset,
          height: size,
          width: size,
        ),
        iconSize: size ?? 30,
        onPressed: onPressed,
      )
      .animate()
      .fadeIn(delay: delay, duration: 600.ms)
      .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), delay: delay, duration: 600.ms)
      .animate(onPlay: (controller) => controller.repeat(reverse: true))
      .scale(
        begin: const Offset(1, 1),
        end: const Offset(1.1, 1.1),
        duration: 1.5.seconds,
        curve: Curves.easeInOut,
      ),
    );
  }
}

// Particle class for background effect
class Particle {
  late double x;
  late double y;
  late double speed;
  late double radius;
  late Color color;
  late double maxY;

  Particle() {
    x = math.Random().nextDouble() * 400;
    y = math.Random().nextDouble() * 800;
    maxY = y; // Original y position (top of the page)
    speed = 0.2 + math.Random().nextDouble() * 1.8;
    radius = 1 + math.Random().nextDouble() * 5;
    
    // Create a blueish color for particles
    final int blue = 150 + math.Random().nextInt(105);
    final int alpha = 50 + math.Random().nextInt(150);
    color = Color.fromARGB(alpha, 50, 100, blue);
  }
  
  void update(double animationValue, Size screenSize, bool fullAnimation) {
    // Move particles upward
    y -= speed;
    
    // Reset the particle when it goes off-screen
    if (y < 0) {
      if (fullAnimation) {
        // If all components are loaded, allow particles to reset from bottom
        y = screenSize.height;
        x = math.Random().nextDouble() * screenSize.width;
      } else {
        // Before all components are loaded, keep particles in their initial position
        y = maxY;
        x = math.Random().nextDouble() * screenSize.width;
      }
    }
  }
}

// Custom painter for animated particles
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;
  final Size screenSize;
  final bool fullAnimation;

  ParticlePainter(this.particles, this.animationValue, this.screenSize, this.fullAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      particle.update(animationValue, screenSize, fullAnimation);
      
      // Don't draw particles that are outside the visible area
      if (particle.x < 0 || particle.x > size.width || 
          particle.y < 0 || particle.y > size.height) {
        continue;
      }
      
      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}