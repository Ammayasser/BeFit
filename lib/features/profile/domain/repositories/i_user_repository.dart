// lib/features/profile/domain/repositories/i_user_repository.dart

import '../entities/user_profile.dart';

abstract class IUserRepository {
  Future<UserProfileEntity?> getUserProfile();
  Future<void> updateUserProfile(UserProfileEntity profile);
  Future<String?> uploadAvatar(String filePath);
}
