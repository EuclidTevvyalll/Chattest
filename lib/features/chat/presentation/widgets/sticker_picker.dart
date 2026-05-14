import 'package:flutter/material.dart';
import 'package:forgelink/widgets/liquidglass_container.dart';
import 'package:forgelink/theme/theme_colors.dart';
import 'package:forgelink/theme/text_theme.dart';

class StickerPicker extends StatelessWidget {
  final Function(String stickerPath) onStickerSelected;

  const StickerPicker({
    super.key,
    required this.onStickerSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // List of stickers from assets
    // In a real app, this would be dynamic or from a manifest
    final stickers = List.generate(8, (index) => 'assets/stickers/pack1/sticker${index + 1}.webm');

    return GlassBox(
      padding: const EdgeInsets.all(16),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      opacity: isDark ? 0.3 : 0.1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Стикеры',
            style: ThemeTextStyles.h3(isDark: isDark),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: stickers.length,
              itemBuilder: (context, index) {
                return _StickerItem(
                  path: stickers[index],
                  onTap: () => onStickerSelected(stickers[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StickerItem extends StatelessWidget {
  final String path;
  final VoidCallback onTap;

  const _StickerItem({
    required this.path,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Since we can't easily show a preview of WEBM in a grid without many players,
    // we'll just show a placeholder or a static frame if we had one.
    // For now, let's use an icon or a simple box.
    // Ideally, we'd have a .png or .webp preview for each sticker.
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: const Center(
          child: Icon(
            Icons.sticky_note_2_rounded,
            color: ThemeColors.blue,
            size: 32,
          ),
        ),
      ),
    );
  }
}
