import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:forgelink/features/auth/domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;

  SupabaseAuthRepository(this._client);

  @override
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  @override
  Future<void> login(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> register(String email, String password, String username) async {
    final cleanUsername = username.trim();
    final cleanEmail = email.trim();

    // Check if the username is already taken
    final existing = await _client
        .from('profiles')
        .select('id')
        .eq('username', cleanUsername)
        .maybeSingle();

    if (existing != null) {
      throw const AuthException('username_already_taken', statusCode: '400');
    }

    final response = await _client.auth.signUp(
      email: cleanEmail,
      password: password,
      data: {'username': cleanUsername},
    );

    if (response.user != null) {
      await _client.from('profiles').upsert({
        'id': response.user!.id,
        'username': cleanUsername,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  @override
  Future<void> logout() async {
    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      try {
        await _client
            .from('profiles')
            .update({
              'is_online': false,
              'last_seen': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', userId);
      } catch (_) {}
    }
    await _client.auth.signOut();
  }

  @override
  User? get currentUser => _client.auth.currentUser;
}
