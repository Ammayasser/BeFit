import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../profile/presentation/providers/user_provider.dart';

/// Canonical SQLite / API user key — always prefer auth user id.
class WorkoutUserResolver {
  WorkoutUserResolver._();

  static String resolve(BuildContext context) {
    final auth = context.read<AuthProvider>();
    if (auth.userId != null && auth.userId!.trim().isNotEmpty) {
      return auth.userId!.trim();
    }
    final user = context.read<UserProvider>();
    if (user.email.trim().isNotEmpty) return user.email.trim();
    if (user.hasProfile && user.displayName.trim().isNotEmpty) {
      return user.displayName.trim();
    }
    return 'guest';
  }

  /// Legacy key used before id fix (display name) — for one-time migration.
  static String? legacyDisplayNameKey(BuildContext context) {
    final user = context.read<UserProvider>();
    if (!user.hasProfile) return null;
    final name = user.displayName.trim();
    if (name.isEmpty) return null;
    final canonical = resolve(context);
    if (name == canonical) return null;
    return name;
  }
}
