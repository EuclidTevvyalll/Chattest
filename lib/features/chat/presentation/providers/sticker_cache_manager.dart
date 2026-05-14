import 'package:video_player/video_player.dart';

/// Менеджер для предварительной подготовки стикеров.
/// Теперь он не хранит активные контроллеры (чтобы избежать ошибок GPU),
/// а только помогает с предварительной загрузкой ассетов.
class StickerCacheManager {
  static final StickerCacheManager _instance = StickerCacheManager._internal();
  factory StickerCacheManager() => _instance;
  StickerCacheManager._internal();

  final Map<String, bool> _prefetched = {};

  /// Предварительная загрузка пака стикеров.
  /// Мы инициализируем контроллер и тут же удаляем его.
  /// Это заставляет систему закэшировать файл в памяти/на диске,
  /// что ускоряет последующее открытие в StickerWidget.
  Future<void> precachePack(List<String> assetPaths) async {
    for (final path in assetPaths) {
      if (_prefetched[path] == true) continue;

      try {
        final controller = VideoPlayerController.asset(path);
        await controller.initialize();
        _prefetched[path] = true;
        await controller.dispose();
        // Небольшая задержка, чтобы не нагружать процессор
        await Future.delayed(const Duration(milliseconds: 50));
      } catch (e) {
        // Log error silently or use debugPrint
      }
    }
  }
}
