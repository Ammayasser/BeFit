import 'dart:math' as math;
import 'package:flutter/material.dart';

class Particle {
  Offset position;
  Offset velocity;
  double radius;
  Color color;
  double opacity;
  double lifeTime; // 0.0 to 1.0

  Particle({
    required this.position,
    required this.velocity,
    required this.radius,
    required this.color,
    this.opacity = 1.0,
    this.lifeTime = 0.0,
  });
}

class VictoryParticleBurst extends CustomPainter {
  final List<Particle> particles;

  VictoryParticleBurst({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.opacity * (1.0 - p.lifeTime))
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(p.position, p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant VictoryParticleBurst oldDelegate) {
    return true; // Always repaint during animation
  }
}

class ParticleBurstWidget extends StatefulWidget {
  final Offset center;
  const ParticleBurstWidget({super.key, required this.center});

  @override
  State<ParticleBurstWidget> createState() => _ParticleBurstWidgetState();
}

class _ParticleBurstWidgetState extends State<ParticleBurstWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..addListener(() {
        _updateParticles();
      });

    _initParticles();
    _controller.forward();
  }

  void _initParticles() {
    final colors = [
      const Color(0xFFFFD700),
      const Color(0xFFFFA500),
      const Color(0xFFFF8C00),
      const Color(0xFFFFB347),
      const Color(0xFFFFDF00),
    ];

    for (int i = 0; i < 30; i++) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final speed = 100 + _random.nextDouble() * 200;
      
      _particles.add(Particle(
        position: widget.center,
        velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
        radius: 2 + _random.nextDouble() * 4,
        color: colors[_random.nextInt(colors.length)],
      ));
    }
  }

  void _updateParticles() {
    final dt = 1 / 60; // Assume 60fps for simplicity in this logic
    final progress = _controller.value;

    for (final p in _particles) {
      p.lifeTime = progress;
      p.position += p.velocity * dt;
      // Deceleration
      p.velocity *= 0.95;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      height: 400,
      child: CustomPaint(
        painter: VictoryParticleBurst(particles: _particles),
      ),
    );
  }
}
