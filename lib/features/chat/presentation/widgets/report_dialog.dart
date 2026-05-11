import 'package:flutter/material.dart';
import 'package:forgelink/theme/theme_colors.dart';
import 'package:forgelink/theme/text_theme.dart';
import 'package:forgelink/widgets/liquidglass_container.dart';

class ReportDialog extends StatefulWidget {
  final String targetId;
  final String targetType;
  final Function(String reason, String? details) onReport;

  const ReportDialog({
    super.key,
    required this.targetId,
    required this.targetType,
    required this.onReport,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final TextEditingController _detailsController = TextEditingController();
  String? _selectedReason;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reasons = [
      {'label': 'Спам', 'value': 'spam', 'icon': Icons.email_rounded},
      {
        'label': 'Оскорбление',
        'value': 'harassment',
        'icon': Icons.person_off_rounded,
      },
      {'label': 'Насилие', 'value': 'violence', 'icon': Icons.warning_rounded},
      {
        'label': 'Неприемлемый контент',
        'value': 'inappropriate',
        'icon': Icons.visibility_off_rounded,
      },
      {'label': 'Другое', 'value': 'other', 'icon': Icons.more_horiz_rounded},
    ];

    final size = MediaQuery.of(context).size;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: GlassBox(
        padding: const EdgeInsets.all(24),
        borderRadius: BorderRadius.circular(28),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: size.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.report_problem_rounded,
                      color: Colors.redAccent,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Text('Жалоба', style: ThemeTextStyles.h2(isDark: isDark)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Выберите причину жалобы и при желании добавьте комментарий.',
                  style: ThemeTextStyles.bodyMedium(
                    isDark: isDark,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                ...reasons.map((reason) {
                  final isSelected = _selectedReason == reason['value'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => setState(
                        () => _selectedReason = reason['value'] as String,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? ThemeColors.blue.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: isDark ? 0.05 : 0.1,
                                ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? ThemeColors.blue : Colors.white10,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              reason['icon'] as IconData,
                              color: isSelected
                                  ? ThemeColors.blue
                                  : (isDark ? Colors.white70 : Colors.black54),
                              size: 20,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              reason['label'] as String,
                              style: ThemeTextStyles.bodyLarge(
                                isDark: isDark,
                                color: isSelected ? ThemeColors.blue : null,
                              ),
                            ),
                            const Spacer(),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: ThemeColors.blue,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                TextField(
                  controller: _detailsController,
                  maxLines: 3,
                  style: ThemeTextStyles.bodyMedium(isDark: isDark),
                  decoration: InputDecoration(
                    hintText: 'Комментарий (необязательно)...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: isDark ? 0.05 : 0.1,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Отмена',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _selectedReason == null
                            ? null
                            : () {
                                Navigator.pop(context);
                                widget.onReport(
                                  _selectedReason!,
                                  _detailsController.text.trim().isEmpty
                                      ? null
                                      : _detailsController.text.trim(),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          disabledBackgroundColor: Colors.white10,
                        ),
                        child: const Text(
                          'Отправить',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


