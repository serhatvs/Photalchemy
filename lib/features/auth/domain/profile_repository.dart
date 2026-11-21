import 'package:photalchemy/core/storage/firestore_gateway.dart';

/// User profile metadata persisted in `/users/{userId}`.
///
/// Follows PRIVACY.md data minimization: stores only coarse cell visit counts
/// and notification consent, never raw photos or precise GPS trails.
class UserProfile {
  UserProfile({
    required this.id,
    this.email,
    this.displayName,
    required this.isAnonymous,
    this.notificationsEnabled = false,
    Map<String, int>? cellCaptureCounts,
  }) : cellCaptureCounts = Map.unmodifiable(cellCaptureCounts ?? const {}) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'User profile id must be nonempty');
    }
    for (final entry in this.cellCaptureCounts.entries) {
      if (entry.key.trim().isEmpty || entry.value < 0) {
        throw ArgumentError(
            'Cell capture counts must have valid keys and >= 0');
      }
    }
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final email = json['email'];
    final displayName = json['displayName'];
    final isAnonymous = json['isAnonymous'];
    final notificationsEnabled = json['notificationsEnabled'];
    final rawCounts = json['cellCaptureCounts'];

    if (id is! String ||
        isAnonymous is! bool ||
        notificationsEnabled is! bool ||
        rawCounts is! Map) {
      throw const FormatException('Invalid or missing UserProfile fields');
    }

    final counts = <String, int>{};
    for (final entry in rawCounts.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String || value is! int) {
        throw const FormatException('Invalid cellCaptureCounts map entry');
      }
      counts[key] = value;
    }

    return UserProfile(
      id: id,
      email: email as String?,
      displayName: displayName as String?,
      isAnonymous: isAnonymous,
      notificationsEnabled: notificationsEnabled,
      cellCaptureCounts: counts,
    );
  }

  final String id;
  final String? email;
  final String? displayName;
  final bool isAnonymous;
  final bool notificationsEnabled;
  final Map<String, int> cellCaptureCounts;

  UserProfile copyWith({
    String? email,
    String? displayName,
    bool? isAnonymous,
    bool? notificationsEnabled,
    Map<String, int>? cellCaptureCounts,
  }) {
    return UserProfile(
      id: id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      cellCaptureCounts: cellCaptureCounts ?? this.cellCaptureCounts,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (email != null) 'email': email,
        if (displayName != null) 'displayName': displayName,
        'isAnonymous': isAnonymous,
        'notificationsEnabled': notificationsEnabled,
        'cellCaptureCounts': Map<String, int>.from(cellCaptureCounts),
      };
}

/// Exception thrown when profile persistence operations fail.
class ProfileRepositoryException implements Exception {
  const ProfileRepositoryException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'ProfileRepositoryException: $message';
}

/// Abstract contract for user-scoped profile storage (`/users/{userId}`).
abstract class ProfileRepository {
  Future<UserProfile?> getProfile({required String userId});

  Future<void> saveProfile({
    required String userId,
    required UserProfile profile,
  });

  Future<UserProfile> incrementCellCapture({
    required String userId,
    required String cellKey,
  });

  Future<void> deleteProfile({required String userId});
}

/// Firestore-backed profile repository enforcing authenticated user access
/// and `firestore.rules` schema invariants.
class FirestoreProfileRepository implements ProfileRepository {
  FirestoreProfileRepository({
    required this.gateway,
    required this.authenticatedUidProvider,
  });

  final FirestoreGateway gateway;
  final String? Function() authenticatedUidProvider;

  @override
  Future<UserProfile?> getProfile({required String userId}) async {
    try {
      final doc = await gateway.getDocument(
        path: 'users/$userId',
        authenticatedUid: authenticatedUidProvider(),
      );
      if (doc == null) return null;
      return UserProfile.fromJson(doc);
    } on FirestoreSecurityException catch (e) {
      throw ProfileRepositoryException(e.message, cause: e);
    }
  }

  @override
  Future<void> saveProfile({
    required String userId,
    required UserProfile profile,
  }) async {
    if (profile.id != userId) {
      throw const ProfileRepositoryException(
        'Profile id does not match target userId.',
      );
    }
    try {
      await gateway.setDocument(
        path: 'users/$userId',
        data: profile.toJson(),
        authenticatedUid: authenticatedUidProvider(),
      );
    } on FirestoreSecurityException catch (e) {
      throw ProfileRepositoryException(e.message, cause: e);
    }
  }

  @override
  Future<UserProfile> incrementCellCapture({
    required String userId,
    required String cellKey,
  }) async {
    final existing = await getProfile(userId: userId) ??
        UserProfile(
          id: userId,
          isAnonymous: false,
        );
    final updatedCounts = Map<String, int>.from(existing.cellCaptureCounts);
    updatedCounts[cellKey] = (updatedCounts[cellKey] ?? 0) + 1;
    final updated = existing.copyWith(cellCaptureCounts: updatedCounts);
    await saveProfile(userId: userId, profile: updated);
    return updated;
  }

  @override
  Future<void> deleteProfile({required String userId}) async {
    try {
      await gateway.deleteDocument(
        path: 'users/$userId',
        authenticatedUid: authenticatedUidProvider(),
      );
    } on FirestoreSecurityException catch (e) {
      throw ProfileRepositoryException(e.message, cause: e);
    }
  }
}
