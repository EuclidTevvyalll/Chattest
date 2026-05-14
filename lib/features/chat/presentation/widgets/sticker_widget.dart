import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:forgelink/theme/theme_colors.dart';
import 'package:visibility_detector/visibility_detector.dart';

class StickerWidget extends StatefulWidget {
  final String assetPath;
  final double size;

  const StickerWidget({super.key, required this.assetPath, this.size = 150});

  @override
  State<StickerWidget> createState() => _StickerWidgetState();
}

class _StickerWidgetState extends State<StickerWidget> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _error = false;
  bool _isVisible =
      true; // По умолчанию считаем видимым, чтобы сразу начать играть

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    try {
      _disposeController(); // На всякий случай очищаем старый

      _controller = VideoPlayerController.asset(widget.assetPath);

      // Настройка перед инициализацией
      await _controller!.initialize();
      await _controller!.setLooping(true);
      await _controller!.setVolume(
        0,
      ); // Отключаем звук, чтобы не конфликтовать с аудио-системой

      if (mounted) {
        setState(() {
          _initialized = true;
        });

        // Сразу запускаем. Если VisibilityDetector позже скажет, что не виден - поставим на паузу.
        _controller!.play();
      }
    } catch (e) {
      debugPrint('Error initializing sticker ${widget.assetPath}: $e');
      if (mounted) {
        setState(() {
          _error = true;
        });
      }
    }
  }

  @override
  void didUpdateWidget(StickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _initController();
    }
  }

  void _disposeController() {
    if (_controller != null) {
      _controller!.pause();
      _controller!.dispose();
      _controller = null;
    }
    _initialized = false;
    _error = false;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Используем более точный ключ для детектора
    final detectorKey = Key(
      'vis_${widget.assetPath}_${identityHashCode(this)}',
    );

    return VisibilityDetector(
      key: detectorKey,
      onVisibilityChanged: (info) {
        if (!mounted || _controller == null || !_initialized) return;

        final visible = info.visibleFraction > 0.05; // Виден хотя бы чуть-чуть
        if (visible != _isVisible) {
          _isVisible = visible;
          if (_isVisible) {
            _controller?.play();
          } else {
            _controller?.pause();
          }
        }
      },
      child: RepaintBoundary(
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: _error
              ? const Icon(Icons.error_outline, color: Colors.redAccent)
              : (_initialized && _controller != null)
              ? FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                )
              : const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ThemeColors.blue,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
