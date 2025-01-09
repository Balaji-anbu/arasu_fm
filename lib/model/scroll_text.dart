import 'package:flutter/material.dart';

class ScrollingTextWithGradient extends StatefulWidget {
  final String text;
  final Duration duration;
  final List<Color> gradientColors;

  const ScrollingTextWithGradient({
    super.key,
    required this.text,
    required this.duration,
    required this.gradientColors,
  });

  @override
  State<ScrollingTextWithGradient> createState() =>
      _ScrollingTextWithGradientState();
}

class _ScrollingTextWithGradientState extends State<ScrollingTextWithGradient>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scrollAnimation;
  double _textWidth = 0; // Default value to avoid LateInitializationError
  double _screenWidth = 0; // Default value to avoid LateInitializationError
  bool _isTextMeasured = false; // Flag to check if text is measured

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
    _scrollAnimation = Tween<double>(begin: 0.9, end: -1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _screenWidth = constraints.maxWidth;

        return SizedBox(
          height: 50,
          child: Stack(
            children: [
              if (!_isTextMeasured) // Measure the text width only once
                Opacity(
                  opacity: 0.0, // Make the measurement invisible
                  child: MeasureSize(
                    onSize: (size) {
                      setState(() {
                        _textWidth = size.width;
                        _isTextMeasured = true;
                      });
                    },
                    child: Text(
                      widget.text,
                      style: const TextStyle(
                          fontSize: 24, fontFamily: 'metropolis'),
                    ),
                  ),
                ),
              if (_isTextMeasured) // Render animation only after measuring text
                AnimatedBuilder(
                  animation: _scrollAnimation,
                  builder: (context, child) {
                    return ClipRect(
                      child: Stack(
                        children: [
                          Positioned(
                            left: _scrollAnimation.value *
                                (_screenWidth + _textWidth - 200),
                            child: GradientText(
                              text: widget.text,
                              gradient: LinearGradient(
                                colors: widget.gradientColors,
                              ),
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'metropolis'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom Gradient Text Widget
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Gradient gradient;

  const GradientText({
    required this.text,
    required this.style,
    required this.gradient,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return gradient.createShader(bounds);
      },
      child: Text(
        text,
        style: style.copyWith(color: Colors.white),
      ),
    );
  }
}

/// Widget to Measure Size of Text
typedef SizeCallback = void Function(Size size);

class MeasureSize extends StatefulWidget {
  final Widget child;
  final SizeCallback onSize;

  const MeasureSize({super.key, required this.child, required this.onSize});

  @override
  State<MeasureSize> createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<MeasureSize> {
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      widget.onSize(renderBox.size);
    });
    return widget.child;
  }
}
