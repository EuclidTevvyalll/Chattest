import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:forgelink/theme/theme_colors.dart';
import 'package:forgelink/widgets/liquidglass_container.dart';

class AvatarCropDialog extends StatefulWidget {
  final Uint8List image;

  const AvatarCropDialog({super.key, required this.image});

  @override
  State<AvatarCropDialog> createState() => _AvatarCropDialogState();
}

class _AvatarCropDialogState extends State<AvatarCropDialog> {
  final _cropController = CropController();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: GlassBox(
        padding: const EdgeInsets.all(24),
        borderRadius: BorderRadius.circular(32),
        opacity: isDark ? 0.2 : 0.1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Обрезать аватар',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 350,
                width: double.infinity,
                child: Stack(
                  children: [
                    Crop(
                      image: widget.image,
                      controller: _cropController,
                      onCropped: (result) async {
                        if (result is CropSuccess) {
                          setState(() => _isProcessing = true);

                          final navigator = Navigator.of(context);
                          try {
                            final processedImage = _processImage(
                              result.croppedImage,
                            );
                            if (mounted) {
                              Future.microtask(
                                () => navigator.pop(processedImage),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              Future.microtask(
                                () => navigator.pop(result.croppedImage),
                              );
                            }
                          }
                        }
                        if (mounted) setState(() => _isProcessing = false);
                      },
                      aspectRatio: 1,
                      withCircleUi: true,
                      baseColor: isDark
                          ? const Color(0xFF1A1A2E)
                          : Colors.white,
                      maskColor: Colors.black.withValues(alpha: 0.6),
                      interactive: !_isProcessing,
                    ),
                    if (_isProcessing)
                      Container(
                        color: Colors.black.withValues(alpha: 0.3),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isProcessing
                        ? null
                        : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Отмена',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing
                        ? null
                        : () => _cropController.crop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeColors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Подтвердить',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Independent function to be run in a separate isolate
Uint8List _processImage(Uint8List input) {
  final image = img.decodeImage(input);
  if (image == null) return input;

  // Normal high quality mode since we are using stable Edge Functions now.
  final resized = img.copyResize(
    image,
    width: 600,
    height: 600,
    interpolation: img.Interpolation.linear,
  );
  final processed = Uint8List.fromList(img.encodeJpg(resized, quality: 85));

  debugPrint('Avatar size: ${processed.length} bytes (High Quality Mode)');
  return processed;
}


