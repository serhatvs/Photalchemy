import 'package:flutter/material.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({
    super.key,
    this.hasPermission = true,
    this.onRequestPermission,
    this.onCapture,
  });

  final bool hasPermission;
  final VoidCallback? onRequestPermission;
  final VoidCallback? onCapture;

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
}
