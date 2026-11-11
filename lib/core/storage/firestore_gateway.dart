/// Exception thrown when a Firestore operation violates security rules,
/// authentication requirements, or network availability.
class FirestoreSecurityException implements Exception {
  const FirestoreSecurityException(this.code, this.message);

  final String
      code; // e.g. 'permission-denied', 'unauthenticated', 'unavailable'
  final String message;

  @override
  String toString() => 'FirestoreSecurityException($code): $message';
}

/// Abstract document-store gateway decoupling domain/data repositories from
/// the platform Firebase SDK so security rules, offline states, and cross-user
/// access barriers can be deterministically verified in CI.
abstract class FirestoreGateway {
  Future<Map<String, dynamic>?> getDocument({
    required String path,
    required String? authenticatedUid,
  });

  Future<List<Map<String, dynamic>>> getCollection({
    required String collectionPath,
    required String? authenticatedUid,
  });

  Future<void> setDocument({
    required String path,
    required Map<String, dynamic> data,
    required String? authenticatedUid,
  });

  Future<void> deleteDocument({
    required String path,
    required String? authenticatedUid,
  });
}

/// Deterministic in-memory Firestore gateway that enforces the exact rules
/// defined in `firestore.rules`:
/// - Default deny for unknown collections
/// - Unauthenticated access rejected (`unauthenticated`)
/// - Cross-user access rejected (`permission-denied`)
/// - Schema validation for `/users/{userId}` and `/users/{userId}/cards/{cardId}`
class RuleEnforcingInMemoryFirestoreGateway implements FirestoreGateway {
  RuleEnforcingInMemoryFirestoreGateway({this.simulateOffline = false});

  bool simulateOffline;
  final Map<String, Map<String, dynamic>> _documents = {};

  static const _validCardTypes = {'attack', 'defense', 'stun', 'reflect'};
  static const _validRarities = {'common', 'uncommon', 'rare', 'epic'};

  void _checkNetwork() {
    if (simulateOffline) {
      throw const FirestoreSecurityException(
        'unavailable',
        'Firestore service is currently unavailable (offline mode).',
      );
    }
  }

  String _requireAuthenticated(String? authenticatedUid) {
    if (authenticatedUid == null || authenticatedUid.trim().isEmpty) {
      throw const FirestoreSecurityException(
        'unauthenticated',
        'Request requires an authenticated Firebase user.',
      );
    }
    return authenticatedUid;
  }

  List<String> _parseSegments(String path) =>
      path.split('/').where((s) => s.isNotEmpty).toList();

  void _authorizeReadPath(List<String> segments, String? authenticatedUid) {
    final uid = _requireAuthenticated(authenticatedUid);
    // Allowed paths: users/{userId} or users/{userId}/cards/{cardId}
    if (segments.length == 2 && segments[0] == 'users') {
      if (segments[1] != uid) {
        throw const FirestoreSecurityException(
          'permission-denied',
          'Cross-user profile read denied by firestore.rules.',
        );
      }
      return;
    }
    if (segments.length == 4 &&
        segments[0] == 'users' &&
        segments[2] == 'cards') {
      if (segments[1] != uid) {
        throw const FirestoreSecurityException(
          'permission-denied',
          'Cross-user card read denied by firestore.rules.',
        );
      }
      return;
    }
    throw const FirestoreSecurityException(
      'permission-denied',
      'Default-deny rule blocked access to path.',
    );
  }

  void _authorizeWritePath(
    List<String> segments,
    Map<String, dynamic> data,
    String? authenticatedUid,
  ) {
    final uid = _requireAuthenticated(authenticatedUid);

    if (segments.length == 2 && segments[0] == 'users') {
      final userId = segments[1];
      if (userId != uid) {
        throw const FirestoreSecurityException(
          'permission-denied',
          'Cross-user profile write denied by firestore.rules.',
        );
      }
      if (!_isValidProfilePayload(userId, data)) {
        throw const FirestoreSecurityException(
          'permission-denied',
          'Invalid profile payload rejected by firestore.rules.',
        );
      }
      return;
    }

    if (segments.length == 4 &&
        segments[0] == 'users' &&
        segments[2] == 'cards') {
      final userId = segments[1];
      final cardId = segments[3];
      if (userId != uid) {
        throw const FirestoreSecurityException(
          'permission-denied',
          'Cross-user card write denied by firestore.rules.',
        );
      }
      final normalized = segments.join('/');
      if (_documents.containsKey(normalized)) {
        throw const FirestoreSecurityException(
          'permission-denied',
          'Card updates are denied by firestore.rules (cards are immutable once minted).',
        );
      }
      if (!_isValidCardPayload(userId, cardId, data)) {
        throw const FirestoreSecurityException(
          'permission-denied',
          'Invalid card payload rejected by firestore.rules.',
        );
      }
      return;
    }

    throw const FirestoreSecurityException(
      'permission-denied',
      'Default-deny rule blocked write to path.',
    );
  }

  bool _isValidProfilePayload(String userId, Map<String, dynamic> data) {
    final id = data['id'];
    final isAnonymous = data['isAnonymous'];
    final notificationsEnabled = data['notificationsEnabled'];
    final cellCaptureCounts = data['cellCaptureCounts'];

    return id is String &&
        id == userId &&
        isAnonymous is bool &&
        notificationsEnabled is bool &&
        cellCaptureCounts is Map;
  }

  bool _isValidCardPayload(
    String userId,
    String cardId,
    Map<String, dynamic> data,
  ) {
    final id = data['id'];
    final ownerId = data['ownerId'];
    final type = data['type'];
    final rarity = data['rarity'];
    final stats = data['stats'];
    final generationVersion = data['generationVersion'];

    if (id is! String || id != cardId) return false;
    if (ownerId is! String || ownerId != userId) return false;
    if (type is! String || !_validCardTypes.contains(type)) return false;
    if (rarity is! String || !_validRarities.contains(rarity)) return false;
    if (generationVersion is! String || generationVersion.trim().isEmpty) {
      return false;
    }
    if (stats is! Map) return false;
    final strength = stats['strength'];
    if (strength is! int || strength < 1 || strength > 10) return false;

    return true;
  }

  @override
  Future<Map<String, dynamic>?> getDocument({
    required String path,
    required String? authenticatedUid,
  }) async {
    _checkNetwork();
    final segments = _parseSegments(path);
    _authorizeReadPath(segments, authenticatedUid);
    final normalized = segments.join('/');
    final stored = _documents[normalized];
    if (stored == null) return null;
    return Map<String, dynamic>.from(stored);
  }

  @override
  Future<List<Map<String, dynamic>>> getCollection({
    required String collectionPath,
    required String? authenticatedUid,
  }) async {
    _checkNetwork();
    final uid = _requireAuthenticated(authenticatedUid);
    final segments = _parseSegments(collectionPath);

    if (segments.length != 3 ||
        segments[0] != 'users' ||
        segments[2] != 'cards') {
      throw const FirestoreSecurityException(
        'permission-denied',
        'Default-deny rule blocked collection query.',
      );
    }
    if (segments[1] != uid) {
      throw const FirestoreSecurityException(
        'permission-denied',
        'Cross-user collection query denied by firestore.rules.',
      );
    }

    final prefix = '${segments.join('/')}/';
    final results = <Map<String, dynamic>>[];
    for (final entry in _documents.entries) {
      if (entry.key.startsWith(prefix)) {
        results.add(Map<String, dynamic>.from(entry.value));
      }
    }
    return results;
  }

  @override
  Future<void> setDocument({
    required String path,
    required Map<String, dynamic> data,
    required String? authenticatedUid,
  }) async {
    _checkNetwork();
    final segments = _parseSegments(path);
    _authorizeWritePath(segments, data, authenticatedUid);
    final normalized = segments.join('/');
    _documents[normalized] = Map<String, dynamic>.from(data);
  }

  @override
  Future<void> deleteDocument({
    required String path,
    required String? authenticatedUid,
  }) async {
    _checkNetwork();
    final segments = _parseSegments(path);
    _authorizeReadPath(segments, authenticatedUid);
    final normalized = segments.join('/');
    _documents.remove(normalized);
  }
}
