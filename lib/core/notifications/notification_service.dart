import 'dart:async';

enum NotificationPermissionStatus {
  notDetermined,
  granted,
  denied,
}

/// Represents an opted-in game notification delivered via FCM or local test trigger.
class GameNotification {
  const GameNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.topic,
  });

  final String id;
  final String title;
  final String body;
  final String topic;
}

/// Abstract contract for Firebase Cloud Messaging (FCM) notification management.
///
/// Complies with PRIVACY.md: notifications are strictly opt-in, explain their
/// purpose, and degrade gracefully if permission is denied.
abstract class NotificationService {
  NotificationPermissionStatus get permissionStatus;

  Set<String> get subscribedTopics;

  Stream<GameNotification> get onNotification;

  Future<NotificationPermissionStatus> requestPermission();

  Future<void> subscribeToTopic(String topic);

  Future<void> unsubscribeFromTopic(String topic);

  Future<void> sendDemoNotification({
    required String title,
    required String body,
    String topic = 'dungeon_alerts',
  });
}

/// Testable FCM notification service adapter for P1 demonstration and widget tests.
class MockFcmNotificationService implements NotificationService {
  MockFcmNotificationService({
    NotificationPermissionStatus initialStatus =
        NotificationPermissionStatus.notDetermined,
    this.simulateDenial = false,
  }) : _status = initialStatus;

  NotificationPermissionStatus _status;
  bool simulateDenial;
  final Set<String> _topics = {};
  final StreamController<GameNotification> _controller =
      StreamController<GameNotification>.broadcast();
  int _counter = 0;

  @override
  NotificationPermissionStatus get permissionStatus => _status;

  @override
  Set<String> get subscribedTopics => Set.unmodifiable(_topics);

  @override
  Stream<GameNotification> get onNotification => _controller.stream;

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    if (simulateDenial) {
      _status = NotificationPermissionStatus.denied;
      _topics.clear();
      return _status;
    }
    _status = NotificationPermissionStatus.granted;
    return _status;
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    if (topic.trim().isEmpty) {
      throw ArgumentError.value(topic, 'topic', 'Topic must be nonempty');
    }
    if (_status != NotificationPermissionStatus.granted) {
      throw StateError(
        'Cannot subscribe to FCM topic before notification permission is granted.',
      );
    }
    _topics.add(topic);
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    _topics.remove(topic);
  }

  @override
  Future<void> sendDemoNotification({
    required String title,
    required String body,
    String topic = 'dungeon_alerts',
  }) async {
    if (_status != NotificationPermissionStatus.granted) {
      throw StateError(
        'Notification permission is not granted. Enable notifications first.',
      );
    }
    _counter += 1;
    final notification = GameNotification(
      id: 'fcm-msg-$_counter',
      title: title,
      body: body,
      topic: topic,
    );
    _controller.add(notification);
  }

  void dispose() {
    _controller.close();
  }
}
