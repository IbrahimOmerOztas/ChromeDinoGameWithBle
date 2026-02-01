import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'components/player.dart';
import 'components/obstacle.dart';

/// Ana Flame oyun sınıfı - Flappy Bird tarzı
/// BLE sensör Y değeri ile kontrol edilen engel kaçırma oyunu
class ObstacleGame extends FlameGame with HasCollisionDetection {
  // Oyun durumu
  bool isGameOver = false;
  bool isPaused = false;
  int score = 0;
  bool _isLoaded = false; // Oyun yüklendi mi?

  // Oyun bileşenleri (nullable)
  Player? _player;
  SpriteComponent? _background;

  // Engel spawn zamanlayıcısı
  Timer? _obstacleTimer;
  double _obstacleSpawnInterval = 1.8; // saniye - boru aralığı
  double _timeSinceLastSpawn = 0;
  static const double _minSpawnInterval = 1.2; // minimum spawn aralığı

  // Oyun hızı (zaman geçtikçe artar)
  double obstacleSpeed = 180; // Boru hızı

  // Callback'ler
  final VoidCallback? onGameOver;
  final void Function(int score)? onScoreUpdate;

  ObstacleGame({
    this.onGameOver,
    this.onScoreUpdate,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Arka plan ekle
    final bgSprite = await loadSprite('background.png');
    _background = SpriteComponent(
      sprite: bgSprite,
      size: size,
      position: Vector2.zero(),
    );
    add(_background!);

    // Oyuncuyu ekle
    _player = Player();
    add(_player!);

    _isLoaded = true;
  }

  @override
  Color backgroundColor() => const Color(0xFF87CEEB); // Gökyüzü mavisi

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Arka planı ekran boyutuna göre ayarla (sadece yüklendiyse)
    if (_isLoaded && _background != null) {
      _background!.size = size;
    }
  }

  @override
  void update(double dt) {
    if (!_isLoaded || isGameOver || isPaused) return;

    super.update(dt);

    // Engel spawn kontrolü
    _timeSinceLastSpawn += dt;
    if (_timeSinceLastSpawn >= _obstacleSpawnInterval) {
      _spawnObstacle();
      _timeSinceLastSpawn = 0;

      // Zamanla zorlaştır - BLE'nin ~50ms notify hızına uygun
      if (_obstacleSpawnInterval > _minSpawnInterval) {
        _obstacleSpawnInterval -= 0.02;
      }
      if (obstacleSpeed < 280) {
        obstacleSpeed += 5;
      }
    }

    // Çarpışma kontrolü
    _checkCollisions();

    // Skor kontrolü
    _checkScore();
  }

  void _spawnObstacle() {
    final obstacle = PipeObstacle.spawn(
      gameWidth: size.x,
      gameHeight: size.y,
      speed: obstacleSpeed,
    );
    add(obstacle);
  }

  void _checkCollisions() {
    if (_player == null) return;

    final pipes = children.whereType<PipeObstacle>().toList();

    for (final pipe in pipes) {
      // Oyuncu rect
      final playerRect = Rect.fromLTWH(
        _player!.position.x + 5, // Biraz tolerans
        _player!.position.y + 5,
        _player!.size.x - 10,
        _player!.size.y - 10,
      );

      // Boru rect'leri ile çarpışma kontrolü
      if (playerRect.overlaps(pipe.getTopPipeRect()) ||
          playerRect.overlaps(pipe.getBottomPipeRect())) {
        _gameOver();
        break;
      }
    }
  }

  void _checkScore() {
    if (_player == null) return;

    final pipes = children.whereType<PipeObstacle>().toList();

    for (final pipe in pipes) {
      // Kuş borudan geçti mi?
      if (!pipe.scored && pipe.position.x + PipeObstacle.pipeWidth < _player!.position.x) {
        pipe.scored = true;
        score++;
        onScoreUpdate?.call(score);
      }
    }
  }

  void _gameOver() {
    isGameOver = true;
    onGameOver?.call();
  }

  /// BLE sensör Y değerini güncelle
  void updatePlayerPosition(double offsetY) {
    if (!_isLoaded || _player == null) return;
    if (!isGameOver && !isPaused) {
      _player!.updateFromSensor(offsetY, size.y);
    }
  }

  /// Oyunu yeniden başlat
  void restart() {
    if (!_isLoaded || _player == null) return;

    // Tüm boruları kaldır
    children.whereType<PipeObstacle>().forEach((p) => p.removeFromParent());

    // Değerleri sıfırla
    isGameOver = false;
    isPaused = false;
    score = 0;
    _timeSinceLastSpawn = 0;
    _obstacleSpawnInterval = 1.8;
    obstacleSpeed = 180;

    // Oyuncuyu merkeze al
    _player!.position.y = size.y / 2 - Player.playerHeight / 2;
    _player!.targetY = _player!.position.y;

    onScoreUpdate?.call(0);
  }

  /// Oyunu duraklat/devam ettir
  void togglePause() {
    isPaused = !isPaused;
  }
}
