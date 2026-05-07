import 'dart:typed_data';
import 'package:rickandmorty/features/chat/domain/models/profile_model.dart';

abstract class ProfileRepository {
  Future<ProfileModel?> getProfile(String id);
  Future<void> updateProfile(ProfileModel profile);
  Future<String> uploadAvatar(Uint8List bytes, String userId);
}
