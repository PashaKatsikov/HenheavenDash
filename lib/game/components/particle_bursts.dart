import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';

/// Small helper that spawns short-lived celebratory particle bursts (coin
/// sparkle for a successful serve, gold stars for combo milestones) using
/// simple procedural circles - lightweight and dependency-free, so it never
/// stutters even with several bursts firing in quick succession.
class ParticleBursts {
  ParticleBursts._();

  static void coinBurst(FlameGame game, Vector2 position) {
    final rng = Random();
    final particle = Particle.generate(
      count: 10,
      lifespan: 0.7,
      generator: (i) {
        final angle = rng.nextDouble() * pi * 2;
        final speed = 60 + rng.nextDouble() * 70;
        return AcceleratedParticle(
          position: position.clone(),
          speed: Vector2(cos(angle), sin(angle)) * speed,
          acceleration: Vector2(0, 220),
          child: CircleParticle(
            radius: 3.5 + rng.nextDouble() * 2,
            paint: Paint()..color = const Color(0xFFFFC94A),
          ),
        );
      },
    );
    game.add(ParticleSystemComponent(particle: particle));
  }

  static void starBurst(FlameGame game, Vector2 position) {
    final rng = Random();
    final particle = Particle.generate(
      count: 14,
      lifespan: 0.9,
      generator: (i) {
        final angle = rng.nextDouble() * pi * 2;
        final speed = 90 + rng.nextDouble() * 90;
        return AcceleratedParticle(
          position: position.clone(),
          speed: Vector2(cos(angle), sin(angle)) * speed,
          acceleration: Vector2(0, 160),
          child: CircleParticle(
            radius: 2.5 + rng.nextDouble() * 2.5,
            paint: Paint()..color = const Color(0xFFFFD966),
          ),
        );
      },
    );
    game.add(ParticleSystemComponent(particle: particle));
  }
}
