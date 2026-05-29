import 'package:video_player/video_player.dart';

class StickerCacheManager {
  static final StickerCacheManager _instance = StickerCacheManager._internal();
  factory StickerCacheManager() => _instance;
  StickerCacheManager._internal();

  final Map<String, bool> _prefetched = {};

  Future<void> precachePack(List<String> assetPaths) async {
    for (final path in assetPaths) {
      if (_prefetched[path] == true) continue;

      try {
        final controller = VideoPlayerController.asset(path);
        await controller.initialize();
        _prefetched[path] = true;
        await controller.dispose();
        await Future.delayed(const Duration(milliseconds: 50));
      } catch (e) {}
    }
  }
}
