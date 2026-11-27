import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photalchemy/app/app_controller.dart';
import 'package:photalchemy/features/exploration/domain/location_service.dart';
import 'package:photalchemy/features/exploration/domain/rarity_policy.dart';
import 'package:photalchemy/features/exploration/presentation/explore_page.dart';

void main() {
  group('SimulatedLocationService', () {
    test('provides default ~1.1km coarse cells and supports cell travel',
        () async {
      final service = SimulatedLocationService();
      expect(service.availableCells, hasLength(4));
      expect(service.currentCellName, 'Campus Plaza');
      expect(service.currentLocation?.cellKey, '38.72:35.48');

      final secondCell = service.availableCells[1];
      service.selectCell(secondCell);

      final snapshot = await service.getCurrentSnapshot();
      expect(snapshot.isLocationActive, isTrue);
      expect(snapshot.cellName, 'Citadel Ruins');
      expect(snapshot.location?.cellKey, '38.75:35.51');
    });

    test('strips coarse location coordinates when opted out or denied',
        () async {
      final service = SimulatedLocationService();
      await service.setOptOut(true);

      expect(service.permission, LocationPermission.optedOut);
      expect(service.currentLocation, isNull);

      final snapshot = await service.getCurrentSnapshot();
      expect(snapshot.isLocationActive, isFalse);
      expect(snapshot.location, isNull);

      await service.setOptOut(false);
      expect(service.permission, LocationPermission.granted);
      expect(service.currentLocation, isNotNull);
    });
  });

  group('AppController multi-cell exploration and anti-farming decay', () {
    test(
        'tracks cell captures per sector, triggers decay at threshold, and resets bonus in new cell',
        () async {
      final locationService = SimulatedLocationService();
      final controller = AppController(locationService: locationService);

      expect(controller.currentCellCaptures, 0);
      expect(controller.isCurrentCellDepleted, isFalse);

      for (var i = 0; i < controller.repeatDecayThreshold; i++) {
        await controller.captureAndTransmute();
      }

      expect(
        controller.currentCellCaptures,
        controller.repeatDecayThreshold,
      );
      expect(controller.isCurrentCellDepleted, isTrue);

      // Travel to Citadel Ruins cell -> fresh capture counter
      controller.selectExplorationCell(controller.availableCells[1]);
      expect(controller.currentCellName, 'Citadel Ruins');
      expect(controller.currentCellCaptures, 0);
      expect(controller.isCurrentCellDepleted, isFalse);
    });

    test('does not increment cell capture count when user opts out of location',
        () async {
      final controller = AppController();
      await controller.toggleLocationOptOut(true);

      expect(controller.locationPermission, LocationPermission.optedOut);
      await controller.captureAndTransmute();
      expect(controller.currentCellCaptures, 0);
    });
  });

  group('ExplorePage location banner and privacy controls', () {
    testWidgets('renders cell chips, decay status, and toggles privacy opt-out',
        (tester) async {
      var optedOutToggled = false;
      ExplorationCellPreset? selectedPreset;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExplorePage(
              locationPermission: LocationPermission.granted,
              currentCellName: 'Campus Plaza',
              currentCellKey: '38.72:35.48',
              currentCellCaptures: 4,
              repeatDecayThreshold: 4,
              availableCells: SimulatedLocationService.defaultCells,
              onSelectCell: (preset) => selectedPreset = preset,
              onToggleLocationOptOut: (optOut) => optedOutToggled = optOut,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('explore_cell_label')), findsOneWidget);
      expect(find.textContaining('Campus Plaza (38.72:35.48)'), findsOneWidget);
      expect(
        find.textContaining('Cell depleted (4/4)'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('cell_chip_38.75:35.51')));
      expect(selectedPreset?.name, 'Citadel Ruins');

      await tester.tap(find.byKey(const Key('location_opt_out_chip')));
      expect(optedOutToggled, isTrue);
    });
  });
}
