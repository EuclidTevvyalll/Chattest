import 'dart:typed_data';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:rickandmorty/theme/theme_colors.dart';
import 'package:rickandmorty/widgets/liquidglass_container.dart';

class AvatarCropDialog extends StatefulWidget {
  final Uint8List image;

  const AvatarCropDialog({super.key, required this.image});

  @override
  State<AvatarCropDialog> createState() => _AvatarCropDialogState();
}

class _AvatarCropDialogState extends State<AvatarCropDialog> {
  final _cropController = CropController();

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
              'Crop Avatar',
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
                child: Crop(
                  image: widget.image,
                  controller: _cropController,
                  onCropped: (result) {
                    if (result is CropSuccess) {
                      Navigator.pop(context, result.croppedImage);
                    }
                  },
                  aspectRatio: 1,
                  withCircleUi: true,
                  baseColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                  maskColor: Colors.black.withValues(alpha: 0.6),
                  interactive: true,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Cancel',
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
                    onPressed: () => _cropController.crop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeColors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
