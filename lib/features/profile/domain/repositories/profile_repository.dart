import 'dart:typed_data';
import 'package:forgelink/features/chat/domain/models/profile_model.dart';

abstract class ProfileRepository {
  Future<ProfileModel?> getProfile(String id);
  Future<String?> getAvatarBase64(String id, {bool priority = false});
  Future<void> updateProfile(ProfileModel profile);
  Future<String> uploadAvatar(Uint8List bytes, String userId);
}


