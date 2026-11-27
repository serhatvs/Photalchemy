import 'package:flutter/material.dart';
import 'package:photalchemy/features/exploration/domain/location_service.dart';
import 'package:photalchemy/features/exploration/domain/rarity_policy.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({
    super.key,
    this.hasPermission = true,
    this.onRequestPermission,
    this.onCapture,
    this.locationPermission = LocationPermission.granted,
    this.currentCellName = 'Campus Plaza',
    this.currentCellKey,
    this.currentCellCaptures = 0,
    this.repeatDecayThreshold = 4,
    this.availableCells = const [],
    this.onSelectCell,
    this.onToggleLocationOptOut,
  });

  final bool hasPermission;
  final VoidCallback? onRequestPermission;
  final VoidCallback? onCapture;
  final LocationPermission locationPermission;
  final String currentCellName;
  final String? currentCellKey;
  final int currentCellCaptures;
  final int repeatDecayThreshold;
  final List<ExplorationCellPreset> availableCells;
  final ValueChanged<ExplorationCellPreset>? onSelectCell;
  final ValueChanged<bool>? onToggleLocationOptOut;

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  bool _isAnalyzing = false;

  void _handleCapture() {
    setState(() => _isAnalyzing = true);
    widget.onCapture?.call();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _isAnalyzing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.hasPermission) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                size: 64,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              Text(
                'Camera Access Required',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Photalchemy needs camera access to sample real-world colors and transmute them into battle cards.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: widget.onRequestPermission,
                icon: const Icon(Icons.check),
                label: const Text('Grant Camera Permission'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isAnalyzing) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Analyzing colors & transmuting card...'),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: _buildLocationBanner(context),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 2,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 72,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Align subject in frame to extract dominant colors',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const Positioned(
                  top: 12,
                  right: 12,
                  child: Chip(
                    avatar: Icon(Icons.palette, size: 16),
                    label: Text('Color-v0 mode'),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
          child: FilledButton.icon(
            onPressed: _handleCapture,
            icon: const Icon(Icons.camera),
            label: const Text('Capture & Transmute'),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationBanner(BuildContext context) {
    final isGranted = widget.locationPermission == LocationPermission.granted;
    final isDepleted =
        isGranted && widget.currentCellCaptures >= widget.repeatDecayThreshold;
    final cellLabel = isGranted && widget.currentCellKey != null
        ? '${widget.currentCellName} (${widget.currentCellKey})'
        : 'Privacy Fallback Mode (No GPS)';
    final statusLabel = !isGranted
        ? 'Color-only baseline rarity active'
        : isDepleted
            ? 'Cell depleted (${widget.currentCellCaptures}/${widget.repeatDecayThreshold}) — anti-farming decay active (Common cap)'
            : 'Exploration bonus active (${widget.currentCellCaptures}/${widget.repeatDecayThreshold} captures in ~1.1km cell)';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  !isGranted
                      ? Icons.location_off_outlined
                      : isDepleted
                          ? Icons.warning_amber_rounded
                          : Icons.explore_outlined,
                  size: 20,
                  color: !isGranted
                      ? Theme.of(context).colorScheme.outline
                      : isDepleted
                          ? Colors.orange
                          : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cellLabel,
                        key: const Key('explore_cell_label'),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Text(
                        statusLabel,
                        key: const Key('explore_rarity_status'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (widget.onToggleLocationOptOut != null)
                  FilterChip(
                    key: const Key('location_opt_out_chip'),
                    label: Text(isGranted ? 'Location On' : 'Opted Out'),
                    selected: isGranted,
                    onSelected: (enabled) =>
                        widget.onToggleLocationOptOut!(!enabled),
                  ),
              ],
            ),
            if (isGranted &&
                widget.availableCells.isNotEmpty &&
                widget.onSelectCell != null) ...[
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: widget.availableCells.map((preset) {
                    final selected = preset.cellKey == widget.currentCellKey;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        key: Key('cell_chip_${preset.cellKey}'),
                        label: Text(preset.name),
                        selected: selected,
                        onSelected: (_) => widget.onSelectCell!(preset),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
