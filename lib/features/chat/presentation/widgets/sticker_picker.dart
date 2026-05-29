import 'package:flutter/material.dart';
import 'package:forgelink/widgets/glass_box.dart';
import 'package:forgelink/features/chat/presentation/widgets/sticker_widget.dart';

class StickerPicker extends StatelessWidget {
  final Function(String stickerPath) onStickerSelected;

  const StickerPicker({super.key, required this.onStickerSelected});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final stickers = List.generate(
      8,
      (index) => 'assets/stickers/pack1/sticker${index + 1}.webm',
    );

    return GlassBox(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      opacity: isDark ? 0.3 : 0.15,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(
            height: 350,
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: stickers.length,
              itemBuilder: (context, index) {
                return _StickerItem(
                  path: stickers[index],
                  onTap: () {
                    Navigator.pop(context);
                    onStickerSelected(stickers[index]);
                  },
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

  const _StickerItem({required this.path, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: StickerWidget(assetPath: path, size: 100),
        ),
      ),
    );
  }
}
