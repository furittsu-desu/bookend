import 'dart:math';
import 'package:flutter/material.dart';

class CompletionCelebration extends StatefulWidget {
  final bool show;
  final Color color;

  const CompletionCelebration({
    super.key,
    required this.show,
    required this.color,
  });

  @override
  State<CompletionCelebration> createState() => _CompletionCelebrationState();
}

class _CompletionCelebrationState extends State<CompletionCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reset();
      }
    });
  }

  @override
  void didUpdateWidget(covariant CompletionCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _generateParticles();
      _controller.forward(from: 0);
    }
  }

  void _generateParticles() {
    _particles.clear();
    for (int i = 0; i < 30; i++) {
      _particles.add(_Particle(
        angle: _random.nextDouble() * 2 * pi,
        speed: 80 + _random.nextDouble() * 180,
        size: 4 + _random.nextDouble() * 6,
        color: HSLColor.fromAHSL(
          1,
          HSLColor.fromColor(widget.color).hue + _random.nextDouble() * 60 - 30,
          0.7 + _random.nextDouble() * 0.3,
          0.5 + _random.nextDouble() * 0.3,
        ).toColor(),
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show && !_controller.isAnimating) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return IgnorePointer(
          child: CustomPaint(
            size: Size.infinite,
            painter: _ParticlePainter(
              particles: _particles,
              progress: _controller.value,
            ),
          ),
        );
      },
    );
  }
}

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, null);
  }
}

class _Particle {
  final double angle;
  final double speed;
  final double size;
  final Color color;

  _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (final p in particles) {
      final distance = p.speed * progress;
      final opacity = (1 - progress).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withAlpha((opacity * 255).toInt())
        ..style = PaintingStyle.fill;
      final offset = Offset(
        center.dx + cos(p.angle) * distance,
        center.dy + sin(p.angle) * distance + 40 * progress * progress,
      );
      canvas.drawCircle(offset, p.size * (1 - progress * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) =>
      old.progress != progress;
}
