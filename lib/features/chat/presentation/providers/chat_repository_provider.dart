import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:forgelink/features/chat/data/repositories/supabase_chat_repository.dart';
import 'package:forgelink/features/chat/domain/repositories/chat_repository.dart';

import 'package:forgelink/core/providers/network/dio_provider.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return SupabaseChatRepository(Supabase.instance.client, dio);
});
