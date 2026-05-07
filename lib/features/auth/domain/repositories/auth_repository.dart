import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  Stream<AuthState> get onAuthStateChange;
  Future<void> login(String email, String password);
  Future<void> register(String email, String password, String username);
  Future<void> logout();
  User? get currentUser;
}
