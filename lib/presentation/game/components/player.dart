import 'dart:ui';
import 'package:flame/components.dart';

/// Oyuncuyu temsil eden kuş bileşeni
/// BLE sensör Y değerine göre yukarı/aşağı hareket eder
class Player extends SpriteComponent with HasGameRef {
  static const double playerWidth = 50;
  static const double playerHeight = 40;

  double targetY = 0;
  double _gameHeight = 0;

  Player() : super(size: Vector2(playerWidth, playerHeight));

  @override
  Future<void> onLoad() async {
    // Kuş sprite'ını yükle
    sprite = await gameRef.loadSprite('bird.png');
    
    _gameHeight = gameRef.size.y;

    // Başlangıç pozisyonu - ekranın ortası, sol tarafta
    position = Vector2(80, _gameHeight / 2 - playerHeight / 2);
    targetY = position.y;
  }

  /// BLE sensör Y değerine göre oyuncu pozisyonunu güncelle
  /// BLE notify hızı tipik olarak ~20-50ms, bu yüzden hızlı tepki gerekli
  /// Sensör değeri: -10.0 ile +10.0 arası (orijin noktasına göre)
  void updateFromSensor(double offsetY, double gameHeight) {
    _gameHeight = gameHeight;
    
    // offsetY değerini oyun koordinatlarına dönüştür
    // offsetY: -10.0 ile +10.0 arası değer (orijin noktasına göre)
    // Negatif = yukarı eğim, Pozitif = aşağı eğim
    
    // Ekranın hareket edilebilir alanını hesapla
    final double playableHeight = _gameHeight - playerHeight - 20; // 10px üst + 10px alt margin
    
    // -10 ile +10 aralığını ekran yüksekliğine map et
    // sensitivity = playableHeight / 20 (toplam aralık)
    final double sensitivity = playableHeight / 20.0;
    final double centerY = _gameHeight / 2 - playerHeight / 2;
    
    // Hedef Y pozisyonunu hesapla
    targetY = centerY + (offsetY * sensitivity);
    
    // Sınırlar içinde tut
    targetY = targetY.clamp(10.0, _gameHeight - playerHeight - 10);
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Yumuşak hareket (lerp) - BLE notify hızına göre optimize edildi
    // Yüksek lerp speed = daha hızlı tepki (~50ms notify için ideal)
    final double lerpSpeed = 12.0;
    position.y += (targetY - position.y) * lerpSpeed * dt;
    
    // Sınırlar içinde tut
    position.y = position.y.clamp(10.0, _gameHeight - playerHeight - 10);
    
    // Kuşun eğim açısını velocity'ye göre ayarla (Flappy Bird efekti)
    final double velocityY = targetY - position.y;
    angle = (velocityY * 0.02).clamp(-0.3, 0.3);
  }
}
