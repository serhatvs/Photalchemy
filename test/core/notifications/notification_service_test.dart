import 'package:flutter_test/flutter_test.dart';
import 'package:photalchemy/core/notifications/notification_service.dart';

void main() {
  group('MockFcmNotificationService', () {
    test('requests permission, subscribes to topics, and emits notifications',
        () async {
      final service = MockFcmNotificationService();
      expect(
        service.permissionStatus,
        NotificationPermissionStatus.notDetermined,
      );

      final status = await service.requestPermission();
      expect(status, NotificationPermissionStatus.granted);

      await service.subscribeToTopic('dungeon_alerts');
      expect(service.subscribedTopics, contains('dungeon_alerts'));

      final received = <GameNotification>[];
      final sub = service.onNotification.listen(received.add);

      await service.sendDemoNotification(
        title: 'Rift Discovered',
        body: 'Capture a photo nearby for bonus rarity.',
      );
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      expect(received.first.title, 'Rift Discovered');
      expect(received.first.topic, 'dungeon_alerts');

      await service.unsubscribeFromTopic('dungeon_alerts');
      expect(service.subscribedTopics, isEmpty);

      await sub.cancel();
      service.dispose();
    });

    test('rejects topic subscription and notifications when permission denied',
        () async {
      final service = MockFcmNotificationService(simulateDenial: true);
      final status = await service.requestPermission();
      expect(status, NotificationPermissionStatus.denied);

      expect(
        () => service.subscribeToTopic('dungeon_alerts'),
        throwsStateError,
      );
      expect(
        () => service.sendDemoNotification(title: 'Test', body: 'Body'),
        throwsStateError,
      );
      service.dispose();
    });
  });
}
