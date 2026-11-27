import 'package:photalchemy/features/exploration/domain/rarity_policy.dart';

/// Named exploration cell representing a coarse ~1.1km quantized area.
class ExplorationCellPreset {
  const ExplorationCellPreset({
    required this.name,
    required this.location,
  });

  final String name;
  final CoarseLocation location;

  String get cellKey => location.cellKey;
}

/// Snapshot of the player's current location permission and coarse cell.
///
/// Complies with PRIVACY.md data minimization: exposes only ~1.1km quantized
/// [CoarseLocation] coordinates when permission is [LocationPermission.granted],
/// and strips coordinates whenever permission is [LocationPermission.denied] or
/// [LocationPermission.optedOut].
class LocationSnapshot {
  const LocationSnapshot({
    required this.permission,
    this.location,
    this.cellName,
  });

  final LocationPermission permission;
  final CoarseLocation? location;
  final String? cellName;

  bool get isLocationActive =>
      permission == LocationPermission.granted && location != null;
}

/// Abstract service providing privacy-preserving coarse location snapshots and
/// runtime permission / opt-out controls.
abstract class LocationService {
  LocationPermission get permission;

  CoarseLocation? get currentLocation;

  String get currentCellName;

  List<ExplorationCellPreset> get availableCells;

  Future<LocationSnapshot> getCurrentSnapshot();

  Future<LocationPermission> requestPermission();

  Future<void> setOptOut(bool optedOut);

  void selectCell(ExplorationCellPreset preset);
}

/// Deterministic, emulator-friendly [LocationService] allowing players and
/// evaluators to travel between distinct coarse ~1.1km cells, test anti-farming
/// decay, and verify privacy opt-out fallbacks without physical GPS movement.
class SimulatedLocationService implements LocationService {
  SimulatedLocationService({
    LocationPermission initialPermission = LocationPermission.granted,
    CoarseLocation? initialLocation,
  }) : _permission = initialPermission {
    if (initialLocation != null) {
      final matching = defaultCells
          .where((c) => c.location == initialLocation)
          .toList(growable: false);
      if (matching.isNotEmpty) {
        _activePreset = matching.first;
      } else {
        _activePreset = ExplorationCellPreset(
          name: 'Custom Sector (${initialLocation.cellKey})',
          location: initialLocation,
        );
      }
    } else {
      _activePreset = defaultCells.first;
    }
  }

  static final List<ExplorationCellPreset> defaultCells = [
    ExplorationCellPreset(
      name: 'Campus Plaza',
      location: CoarseLocation.fromCoordinates(38.7205, 35.4826),
    ),
    ExplorationCellPreset(
      name: 'Citadel Ruins',
      location: CoarseLocation.fromCoordinates(38.7512, 35.5140),
    ),
    ExplorationCellPreset(
      name: 'Volcanic Foothills',
      location: CoarseLocation.fromCoordinates(38.5410, 35.4480),
    ),
    ExplorationCellPreset(
      name: 'Sunken Marsh',
      location: CoarseLocation.fromCoordinates(38.8120, 35.3910),
    ),
  ];

  LocationPermission _permission;
  late ExplorationCellPreset _activePreset;

  @override
  LocationPermission get permission => _permission;

  @override
  CoarseLocation? get currentLocation =>
      _permission == LocationPermission.granted ? _activePreset.location : null;

  @override
  String get currentCellName => _activePreset.name;

  @override
  List<ExplorationCellPreset> get availableCells => defaultCells;

  @override
  Future<LocationSnapshot> getCurrentSnapshot() async {
    return LocationSnapshot(
      permission: _permission,
      location: currentLocation,
      cellName: _activePreset.name,
    );
  }

  @override
  Future<LocationPermission> requestPermission() async {
    _permission = LocationPermission.granted;
    return _permission;
  }

  @override
  Future<void> setOptOut(bool optedOut) async {
    _permission =
        optedOut ? LocationPermission.optedOut : LocationPermission.granted;
  }

  /// Sets the permission state directly (for testing denial and opt-out flows).
  void setPermission(LocationPermission permission) {
    _permission = permission;
  }

  @override
  void selectCell(ExplorationCellPreset preset) {
    _activePreset = preset;
  }
}
