import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:forgelink/features/chat/domain/models/profile_model.dart';
import 'package:forgelink/features/auth/presentation/providers/auth_provider.dart';

class BannedScreen extends ConsumerWidget {
  final ProfileModel profile;

  const BannedScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPermanent = profile.bannedUntil == null;
    final reason = profile.bannedReason ?? 'Нарушение правил сообщества';
    
    final expiredDateText = isPermanent 
        ? 'Никогда' 
        : DateFormat('dd.MM.yyyy HH:mm').format(profile.bannedUntil!.toLocal());

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.block_outlined, size: 100, color: Colors.redAccent),
              const SizedBox(height: 32),
              Text(
                'Ваш аккаунт заблокирован',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('Причина:', reason),
                    const Divider(height: 32),
                    _buildInfoRow(
                      'Блокировка истекает:', 
                      expiredDateText,
                      isPermanent: isPermanent,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(authRepositoryProvider).logout();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Выйти из аккаунта'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isPermanent = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isPermanent ? Colors.redAccent : null,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
