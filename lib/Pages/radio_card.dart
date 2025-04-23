import 'package:arasu_fm/Providers/audio_provider.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:arasu_fm/Pages/audio_data.dart';

class RadioCard extends StatefulWidget {
  final AudioData audioData;
  
  const RadioCard({
    super.key,
    required this.audioData,
  });

  @override
  State<RadioCard> createState() => _RadioCardState();
}

class _RadioCardState extends State<RadioCard> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _hoverController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _pulseAnimation;
  bool _isHovering = false;
  
  @override
  void initState() {
    super.initState();
    // Card entrance animation
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.01, 0.0),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.elasticOut)).animate(_entranceController);
    
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).chain(CurveTween(curve: Curves.easeOutBack)).animate(_entranceController);

    _rotateAnimation = Tween<double>(
      begin: 0.03,
      end: 0.0,
    ).chain(CurveTween(curve: Curves.easeOut)).animate(_entranceController);
    
    // Hover effect animation
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    
    // Pulsing animation for breathing effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).chain(CurveTween(curve: Curves.easeInOut)).animate(_pulseController);
    
    _entranceController.forward();
    _pulseController.repeat(reverse: true);
    
    Future.delayed(const Duration(milliseconds: 200), () {
      _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _hoverController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final audioProvider = Provider.of<AudioProvider>(context);
    final bool isCurrentlyPlaying = audioProvider.currentAudio?.audioUrl == widget.audioData.audioUrl && !audioProvider.isPaused;
    final bool isLoadingThisAudio = audioProvider.currentAudio?.audioUrl == widget.audioData.audioUrl && audioProvider.isLoading;
    
    // Adaptive height based on screen size
    final cardHeight = screenSize.height * 0.13;
    final minHeight = 90.0;
    final maxHeight = 130.0;
    final adaptiveHeight = cardHeight.clamp(minHeight, maxHeight);
    
    // Adaptive font sizes
    final titleFontSize = (screenSize.width < 360) ? 13.0 : 15.0;
    final statusFontSize = (screenSize.width < 360) ? 10.0 : 12.0;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_entranceController, _hoverController, _pulseAnimation]),
      builder: (context, child) {
        return MouseRegion(
          onEnter: (_) => _handleHoverChange(true),
          onExit: (_) => _handleHoverChange(false),
          child: Transform.scale(
            scale: _scaleAnimation.value * (_isHovering ? 1.03 : 1.0) * (isCurrentlyPlaying ? _pulseAnimation.value : 1.0),
            child: Transform.rotate(
              angle: _rotateAnimation.value,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenSize.width * 0.04,
                    vertical: screenSize.height * 0.01,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      _triggerTapAnimation();
                      if (audioProvider.currentAudio?.audioUrl == widget.audioData.audioUrl) {
                        audioProvider.togglePlayPause();
                      } else {
                        audioProvider.playAudio(widget.audioData);
                      }
                    },
                    child: _buildCard(adaptiveHeight, isCurrentlyPlaying, isLoadingThisAudio, screenSize, titleFontSize, statusFontSize),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard(double adaptiveHeight, bool isCurrentlyPlaying, bool isLoadingThisAudio, Size screenSize, double titleFontSize, double statusFontSize) {
    return Hero(
      tag: 'radio_card_${widget.audioData.audioUrl}',
      child: Material(
        color: Colors.transparent,
        elevation: 16 * (_isHovering ? 1.5 : 1.0),
        shadowColor: isCurrentlyPlaying 
          ? Colors.purpleAccent.withOpacity(0.7) 
          : Colors.blueAccent.withOpacity(0.6),
        borderRadius: BorderRadius.circular(28),
        child: Container(
          height: adaptiveHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isCurrentlyPlaying 
                ? [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)]
                : [const Color(0xFF6A11CB), const Color(0xFF2575FC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: (isCurrentlyPlaying 
                  ? Colors.purpleAccent 
                  : Colors.blueAccent)
                  .withOpacity(_isHovering ? 0.6 : 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
            ],
            border: isCurrentlyPlaying
              ? Border.all(
                  color: Colors.white.withOpacity(0.6),
                  width: 2.0,
                )
              : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // Enhanced particle system
                EnhancedParticleOverlay(isPlaying: isCurrentlyPlaying),
                
                // Ripple effect for playing state
                if (isCurrentlyPlaying)
                  const RippleAnimation(),
                
                // Content layer with responsive layout
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    children: [
                      // Radio icon with animation
                      _buildAnimatedIcon(isCurrentlyPlaying),
                      
                      SizedBox(width: screenSize.width * 0.03),
                      
                      // Text content that adapts to screen width
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildShimmerText(
                              "ARASU COMMUNITY RADIO", 
                              titleFontSize, 
                              isCurrentlyPlaying
                            ),
                            const SizedBox(height: 10),
                            _buildStatusIndicator(isCurrentlyPlaying, statusFontSize),
                          ],
                        ),
                      ),
                      
                      // Right side with volume bars or loading indicator
                      isLoadingThisAudio 
                          ? const LoadingIndicator()
                          : isCurrentlyPlaying
                              ? _buildSoundWaveAnimation()
                              : const PlayButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleHoverChange(bool isHovering) {
    setState(() {
      _isHovering = isHovering;
    });
    
    if (isHovering) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  void _triggerTapAnimation() {
    _entranceController.reset();
    _entranceController.forward();
  }

  Widget _buildShimmerText(String text, double fontSize, bool isPlaying) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: isPlaying
              ? [Colors.white, Colors.pinkAccent.shade100, Colors.white]
              : [Colors.white, Colors.lightBlueAccent.shade100, Colors.white],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          tileMode: TileMode.mirror,
        ).createShader(bounds);
      },
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'metropolis',
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.5),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildAnimatedIcon(bool isPlaying) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.05),
                ],
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return RotationTransition(
                  turns: Tween<double>(begin: 0.5, end: 1.0).animate(animation),
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.radio_rounded,
                key: ValueKey<bool>(isPlaying),
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(bool isPlaying, double fontSize) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPlaying
            ? Colors.redAccent.withOpacity(0.3)
            : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPlaying
              ? Colors.redAccent.withOpacity(0.6)
              : Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isPlaying
                ? Colors.redAccent.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPlaying ? Colors.redAccent : Colors.greenAccent,
              boxShadow: [
                BoxShadow(
                  color: (isPlaying ? Colors.redAccent : Colors.greenAccent).withOpacity(0.6),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isPlaying ? 'PLAYING' : 'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundWaveAnimation() {
    return SizedBox(
      width: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          4,
          (index) => AudioBar(
            height: 16.0 + (index * 3.0),
            active: true,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class AudioBar extends StatefulWidget {
  final double height;
  final bool active;
  final Color color;

  const AudioBar({
    super.key,
    required this.height,
    required this.active,
    required this.color,
  });

  @override
  State<AudioBar> createState() => _AudioBarState();
}

class _AudioBarState extends State<AudioBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600 + (math.Random().nextInt(400))),
    );

    _heightAnimation = Tween<double>(
      begin: widget.height * 0.3,
      end: widget.height,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    )..addListener(() {
        setState(() {});
      });

    if (widget.active) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AudioBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) {
      if (widget.active) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3.5,
      height: _heightAnimation.value,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: widget.color.withOpacity(0.7),
            blurRadius: 5,
            spreadRadius: 0.5,
          ),
        ],
      ),
    );
  }
}

class EnhancedParticleOverlay extends StatefulWidget {
  final bool isPlaying;
  
  const EnhancedParticleOverlay({
    super.key,
    required this.isPlaying,
  });

  @override
  State<EnhancedParticleOverlay> createState() => _EnhancedParticleOverlayState();
}

class _EnhancedParticleOverlayState extends State<EnhancedParticleOverlay> with TickerProviderStateMixin {
  late List<Particle> particles;
  late AnimationController _animController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _densityController;
  late Animation<double> _densityAnimation;

  @override
  void initState() {
    super.initState();
    
    // Create enhanced particles with different types
    _initializeParticles();
    
    // Animation controller for particle movement
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // ~60fps
    )..addListener(() {
        _updateParticles();
      });

    // Pulse animation controller
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut))
      ..addListener(() {
        setState(() {});
      });
      
    // Density animation controller - used when playing state changes
    _densityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _densityAnimation = Tween<double>(begin: 0.6, end: 1.2)
        .animate(CurvedAnimation(parent: _densityController, curve: Curves.easeInOut))
      ..addListener(() {
        setState(() {});
      });

    _animController.repeat();
    _pulseController.repeat(reverse: true);
    
    if (widget.isPlaying) {
      _densityController.forward();
    }
  }
  
  @override
  void didUpdateWidget(EnhancedParticleOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _densityController.forward();
        // Add more particles when playing
        _addExtraParticles();
      } else {
        _densityController.reverse();
        // Filter out extra particles when not playing
        _removeExtraParticles();
      }
    }
  }
  
  void _initializeParticles() {
    particles = List.generate(
      35, // Increased number of particles
      (index) => _createParticle(index),
    );
  }
  
  Particle _createParticle(int index) {
    // Create different types of particles
    final particleType = index % 5; // More types for variety
    
    double radius;
    double speed;
    double alpha;
    Color color;
    
    switch (particleType) {
      case 0: // Normal particles
        radius = math.Random().nextDouble() * 2.5 + 1.2;
        speed = math.Random().nextDouble() * 0.8 + 0.5;
        alpha = math.Random().nextDouble() * 0.5 + 0.1;
        color = Colors.white;
        break;
      case 1: // Small fast particles
        radius = math.Random().nextDouble() * 1.0 + 0.6;
        speed = math.Random().nextDouble() * 1.8 + 1.0;
        alpha = math.Random().nextDouble() * 0.3 + 0.1;
        color = Colors.white;
        break;
      case 2: // Large slow particles
        radius = math.Random().nextDouble() * 4.0 + 2.8;
        speed = math.Random().nextDouble() * 0.5 + 0.2;
        alpha = math.Random().nextDouble() * 0.2 + 0.05;
        color = Colors.white;
        break;
      case 3: // Blue tinted particles
        radius = math.Random().nextDouble() * 2.0 + 1.0;
        speed = math.Random().nextDouble() * 1.0 + 0.4;
        alpha = math.Random().nextDouble() * 0.4 + 0.1;
        color = Colors.lightBlueAccent;
        break;
      case 4: // Purple tinted particles (for playing state)
        radius = math.Random().nextDouble() * 2.5 + 1.2;
        speed = math.Random().nextDouble() * 1.2 + 0.6;
        alpha = math.Random().nextDouble() * 0.4 + 0.15;
        color = Colors.purpleAccent;
        break;
      default:
        radius = math.Random().nextDouble() * 2.5 + 1.0;
        speed = math.Random().nextDouble() * 0.8 + 0.5;
        alpha = math.Random().nextDouble() * 0.4 + 0.1;
        color = Colors.white;
    }
    
    return Particle(
      position: Offset(
        math.Random().nextDouble() * 1000, // Wider range for responsive layout
        math.Random().nextDouble() * 200, // Taller range for responsive layout
      ),
      velocity: Offset(
        (math.Random().nextDouble() - 0.5) * speed,
        (math.Random().nextDouble() - 0.5) * speed,
      ),
      radius: radius,
      alpha: alpha,
      targetAlpha: alpha,
      type: particleType,
      color: color,
      originalRadius: radius, // Store original radius for pulsing
    );
  }
  
  void _addExtraParticles() {
    // Add more particles when playing state is activated
    final extraParticles = List.generate(
      15,
      (index) {
        final particle = _createParticle(4); // More purple particles
        // Start small and grow
        particle.radius = 0.1;
        return particle;
      },
    );
    
    setState(() {
      particles.addAll(extraParticles);
    });
  }
  
  void _removeExtraParticles() {
    // Reduce particle count when returning to non-playing state
    if (particles.length > 35) {
      setState(() {
        particles = particles.sublist(0, 35);
      });
    }
  }

  void _updateParticles() {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    setState(() {
      for (var i = 0; i < particles.length; i++) {
        // Update particle position with their own velocity
        particles[i].position += particles[i].velocity;
        
        // Add slight oscillation to particle movement for more natural flow
        final oscillation = math.sin(now * 0.001 + i) * 0.2;
        particles[i].velocity += Offset(oscillation * 0.02, oscillation * 0.01);
        
        // Apply slight drag to keep velocities in check
        particles[i].velocity *= 0.99;

        // Bounce off walls with responsive boundaries (wider range)
        if (particles[i].position.dx < 0 || particles[i].position.dx > 1000) {
          particles[i].velocity = Offset(-particles[i].velocity.dx * 0.85, particles[i].velocity.dy);
        }
        if (particles[i].position.dy < 0 || particles[i].position.dy > 200) {
          particles[i].velocity = Offset(particles[i].velocity.dx, -particles[i].velocity.dy * 0.85);
        }
        
        // Occasionally change alpha for twinkling effect
        if (math.Random().nextDouble() < 0.02) {
          particles[i].targetAlpha = math.Random().nextDouble() * 0.4 + 0.1;
        }
        
        // Pulsing size effect
        final pulseFactor = 1.0 + math.sin(now * 0.001 + i * 0.5) * 0.15;
        particles[i].radius = particles[i].originalRadius * pulseFactor;
        
        // Smoothly transition alpha to target
        if (particles[i].alpha < particles[i].targetAlpha) {
          particles[i].alpha += 0.01;
        } else if (particles[i].alpha > particles[i].targetAlpha) {
          particles[i].alpha -= 0.01;
        }
        
        // Special effects when playing
        if (widget.isPlaying && particles[i].type == 4) {
          // Special movement pattern for "playing" particles
          particles[i].velocity += Offset(
            math.sin(now * 0.002 + i) * 0.03,
            math.cos(now * 0.002 + i) * 0.03
          );
          
          // Make purple particles more visible
          particles[i].alpha = math.max(particles[i].alpha, 0.15);
        }
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _pulseController.dispose();
    _densityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: EnhancedParticlePainter(
              particles: particles,
              pulseValue: _pulseAnimation.value,
              densityFactor: _densityAnimation.value,
              containerSize: constraints,
              isPlaying: widget.isPlaying,
            ),
          ),
        );
      }
    );
  }
}

class Particle {
  Offset position;
  Offset velocity;
  double radius;
  double alpha;
  double targetAlpha;
  double originalRadius;
  int type; // Expanded types
  Color color;

  Particle({
    required this.position,
    required this.velocity,
    required this.radius,
    required this.alpha,
    required this.targetAlpha,
    required this.type,
    required this.color,
    required this.originalRadius,
  });
}

class EnhancedParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double pulseValue;
  final double densityFactor;
  final BoxConstraints containerSize;
  final bool isPlaying;
  
  EnhancedParticlePainter({
    required this.particles,
    required this.pulseValue,
    required this.densityFactor,
    required this.containerSize,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Scale factor to adapt particles to actual container size
    final scaleX = size.width / 1000;
    final scaleY = size.height / 200;
    
    // Draw background effects first
    _drawBackgroundEffects(canvas, size);
    
    // Sort particles by size to create depth perception
    final sortedParticles = [...particles]..sort((a, b) => a.radius.compareTo(b.radius));
    
    for (var particle in sortedParticles) {
      // Scale particle position to actual size
      final scaledPosition = Offset(
        particle.position.dx * scaleX,
        particle.position.dy * scaleY,
      );
      
      // Adjust visual factors based on playing state
      double alphaMultiplier = isPlaying ? 1.2 : 1.0;
      double sizeMultiplier = isPlaying ? densityFactor : 1.0;
      
      // Base particle
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.alpha * pulseValue * alphaMultiplier)
        ..style = PaintingStyle.fill;
      
      final scaledRadius = particle.radius * ((scaleX + scaleY) / 2) * sizeMultiplier;
      canvas.drawCircle(scaledPosition, scaledRadius, paint);
      
      // Glow effect with variable intensity
      double glowIntensity;
      if (particle.type == 2) {
        glowIntensity = 0.5; // Stronger glow for large particles
      } else if (particle.type == 4) {
        glowIntensity = isPlaying ? 0.7 : 0.3; // Special glow for purple particles
      } else {
        glowIntensity = 0.3;
      }
      
      final glowPaint = Paint()
        ..color = particle.color.withOpacity(particle.alpha * glowIntensity * pulseValue)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
        
      canvas.drawCircle(scaledPosition, scaledRadius * 2.5, glowPaint);
    }
    
    // Draw connecting lines with gradient effect
    _drawConnectingLines(canvas, size, scaleX, scaleY);
  }
  
  void _drawBackgroundEffects(Canvas canvas, Size size) {
    // Add subtle radial gradient in the background
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // Background glow based on playing state
    final Paint bgPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, 0.0),
        radius: 1.2,
        colors: isPlaying 
          ? [
              Colors.purple.withOpacity(0.05 * pulseValue), 
              Colors.transparent
            ]
          : [
              Colors.blue.withOpacity(0.03 * pulseValue), 
              Colors.transparent
            ],
        stops: const [0.0, 1.0],
      ).createShader(rect);
      
    canvas.drawRect(rect, bgPaint);
  }

  
    void _drawConnectingLines(Canvas canvas, Size size, double scaleX, double scaleY) {
    // Adjust line parameters based on playing state
    final maxDistance = isPlaying ? 70.0 : 50.0;
    final opacityMultiplier = isPlaying ? 1.5 : 1.0;
    
    for (var i = 0; i < particles.length; i++) {
      for (var j = i + 1; j < particles.length; j++) {
        final p1 = Offset(
          particles[i].position.dx * scaleX,
          particles[i].position.dy * scaleY,
        );
        
        final p2 = Offset(
          particles[j].position.dx * scaleX,
          particles[j].position.dy * scaleY,
        );
        
        final distance = (p1 - p2).distance;
        
        if (distance < maxDistance) {
          // Calculate opacity based on distance and playing state
          final lineOpacity = (1 - distance / maxDistance) * 0.1 * pulseValue * opacityMultiplier;
          
          // Determine line color based on particle types
          List<Color> lineColors;
          if (isPlaying && (particles[i].type == 4 || particles[j].type == 4)) {
            // Purple connections when playing
            lineColors = [
              Colors.purpleAccent.withOpacity(lineOpacity),
              Colors.white.withOpacity(lineOpacity * 0.7),
            ];
          } else if (particles[i].type == 3 || particles[j].type == 3) {
            // Blue connections for blue particles
            lineColors = [
              Colors.blueAccent.withOpacity(lineOpacity),
              Colors.white.withOpacity(lineOpacity * 0.7),
            ];
          } else {
            // Default white/blue connections
            lineColors = [
              Colors.white.withOpacity(lineOpacity),
              Colors.blueAccent.withOpacity(lineOpacity * 0.7),
            ];
          }
          
          final linePaint = Paint()
            ..strokeWidth = (1 - distance / maxDistance) * 0.9 * densityFactor
            ..shader = LinearGradient(
              colors: lineColors,
            ).createShader(Rect.fromPoints(p1, p2));

          canvas.drawLine(p1, p2, linePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// New animated components

class RippleAnimation extends StatefulWidget {
  const RippleAnimation({super.key});

  @override
  State<RippleAnimation> createState() => _RippleAnimationState();
}

class _RippleAnimationState extends State<RippleAnimation> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Animation<double>> _animations = [];
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    
    // Create 3 staggered ripple animations
    for (int i = 0; i < 3; i++) {
      final delay = i * 0.3;
      final begin = 0.0 + delay;
      final end = 1.0 + delay;
      
      _animations.add(
        Tween<double>(begin: begin, end: end).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(
              begin.clamp(0.0, 1.0),
              end.clamp(0.0, 1.0),
              curve: Curves.easeOutQuart,
            ),
          ),
        ),
      );
    }
    
    _controller.repeat();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: RipplePainter(
            animations: _animations.map((anim) => anim.value).toList(),
          ),
          child: Container(),
        );
      },
    );
  }
}

class RipplePainter extends CustomPainter {
  final List<double> animations;
  
  RipplePainter({required this.animations});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    for (int i = 0; i < animations.length; i++) {
      final animValue = animations[i] % 1.0;
      if (animValue < 0.01) continue; // Skip initial frames
      
      final maxRadius = size.width * 0.8;
      final currentRadius = maxRadius * animValue;
      
      final opacity = (1.0 - animValue) * 0.3;
      
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * (1.0 - animValue)
        ..color = Colors.white.withOpacity(opacity);
      
      canvas.drawCircle(center, currentRadius, paint);
    }
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class LoadingIndicator extends StatefulWidget {
  const LoadingIndicator({super.key});

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _controller.repeat();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.2 + (_controller.value * 0.2)),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            // Loading spinner
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color.lerp(Colors.white70, Colors.white, _controller.value)!,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class PlayButton extends StatefulWidget {
  const PlayButton({super.key});

  @override
  State<PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<PlayButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    
    _controller.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                colors: [
                  Colors.white,
                  Colors.lightBlueAccent.shade100,
                  Colors.white,
                ],
                stops: const [0.0, 0.5, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds);
            },
            child: const Icon(
              Icons.play_circle_fill_rounded,
              color: Colors.white,
              size: 36,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}