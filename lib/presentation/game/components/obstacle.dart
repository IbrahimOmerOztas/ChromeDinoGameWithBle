import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';

/// Flappy Bird tarzı boru engeli - üst ve alt borulardan oluşur
/// Ortada kuşun geçebileceği bir boşluk var
class PipeObstacle extends PositionComponent with HasGameRef {
  static const double pipeWidth = 60;
  static const double gapHeight = 180; // Kuşun geçeceği boşluk (artırıldı)

  final double speed;
  final double gapCenterY;
  final double gameHeight; // Spawn anındaki ekran yüksekliği

  // Hesaplanan değerler
  late double topPipeHeight;
  late double bottomPipeY;
  late double bottomPipeHeight;

  bool scored = false; // Skor sayıldı mı?

  PipeObstacle({
    required Vector2 position,
    required this.speed,
    required this.gapCenterY,
    required this.gameHeight,
  }) : super(position: position) {
    // Boru boyutlarını hesapla
    topPipeHeight = (gapCenterY - gapHeight / 2).clamp(0, gameHeight);
    bottomPipeY = gapCenterY + gapHeight / 2;
    bottomPipeHeight = (gameHeight - bottomPipeY).clamp(0, gameHeight);
  }

  @override
  Future<void> onLoad() async {
    final pipeSprite = await gameRef.loadSprite('pipe.png');

    // Üst boru - yukarıdan aşağı uzanır
    if (topPipeHeight > 0) {
      final topPipe = SpriteComponent(
        sprite: pipeSprite,
        size: Vector2(pipeWidth, topPipeHeight),
        position: Vector2(0, 0),
        anchor: Anchor.topLeft,
      );
      // Sprite'ı dikey olarak çevir (boru ağzı aşağı baksın)
      topPipe.flipVertically();
      topPipe.position = Vector2(0, topPipeHeight); // Flip sonrası pozisyon düzeltmesi
      add(topPipe);
    }

    // Alt boru - aşağıdan yukarı uzanır
    if (bottomPipeHeight > 0) {
      final bottomPipe = SpriteComponent(
        sprite: pipeSprite,
        size: Vector2(pipeWidth, bottomPipeHeight),
        position: Vector2(0, bottomPipeY),
        anchor: Anchor.topLeft,
      );
      add(bottomPipe);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Sola doğru hareket
    position.x -= speed * dt;

    // Ekrandan çıktıysa kaldır
    if (position.x < -pipeWidth) {
      removeFromParent();
    }
  }

  /// Çarpışma kontrolü için üst boru rect'i
  Rect getTopPipeRect() {
    return Rect.fromLTWH(position.x, 0, pipeWidth, topPipeHeight);
  }

  /// Çarpışma kontrolü için alt boru rect'i
  Rect getBottomPipeRect() {
    return Rect.fromLTWH(position.x, bottomPipeY, pipeWidth, bottomPipeHeight);
  }

  /// Rastgele pozisyonda boru engeli oluştur
  static PipeObstacle spawn({
    required double gameWidth,
    required double gameHeight,
    required double speed,
  }) {
    final random = Random();

    // Boşluğun merkez Y pozisyonu (ekranın %30-%70 arası - daha güvenli)
    final minY = gameHeight * 0.30;
    final maxY = gameHeight * 0.70;
    final gapY = minY + random.nextDouble() * (maxY - minY);

    return PipeObstacle(
      position: Vector2(gameWidth + 10, 0),
      speed: speed,
      gapCenterY: gapY,
      gameHeight: gameHeight,
    );
  }
}
