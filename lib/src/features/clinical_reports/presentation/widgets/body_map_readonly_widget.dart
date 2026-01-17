import 'package:flutter/material.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/entities/clinical_report.dart';

/// Read-only widget that displays only body map views that have markers.
class BodyMapReadOnlyWidget extends StatelessWidget {
  final List<BodyMarker> markers;

  const BodyMapReadOnlyWidget({super.key, required this.markers});

  static const Map<String, String> viewTitles = {
    'front': 'Front View',
    'back': 'Back View',
    'lateral': 'Lateral View',
  };

  static const Map<String, Map<String, dynamic>> markerTypes = {
    'pain': {'label': 'Pain', 'color': '#D32F2F', 'icon': Icons.location_on},
    'injury': {'label': 'Injury', 'color': '#F57C00', 'icon': Icons.healing},
    'rash': {'label': 'Rash', 'color': '#7B1FA2', 'icon': Icons.bubble_chart},
    'scar': {'label': 'Scar', 'color': '#616161', 'icon': Icons.linear_scale},
    'other': {'label': 'Other', 'color': '#1976D2', 'icon': Icons.location_on},
  };

  Color _parseColor(String hexColor) {
    final color = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$color', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    // Group markers by model and view
    final Map<String, Map<String, List<BodyMarker>>> groupedMarkers = {};

    for (final marker in markers) {
      final modelId = marker.modelId ?? 'skin';
      final view = marker.view;

      groupedMarkers.putIfAbsent(modelId, () => {});
      groupedMarkers[modelId]!.putIfAbsent(view, () => []);
      groupedMarkers[modelId]![view]!.add(marker);
    }

    if (groupedMarkers.isEmpty) {
      return const Center(child: Text('No markers to display'));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: groupedMarkers.keys.map((modelId) {
          final viewsForModel = groupedMarkers[modelId]!;

          return Card(
            margin: const EdgeInsets.only(bottom: 24),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Model Header
                  Text(
                    _getModelTitle(modelId),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Views for this model
                  ...viewsForModel.entries.map((viewEntry) {
                    final view = viewEntry.key;
                    final markersForView = viewEntry.value;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // View title
                          Text(
                            viewTitles[view] ?? view.toUpperCase(),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),

                          // Image with markers overlay
                          _buildMarkedImage(modelId, view, markersForView),

                          const SizedBox(height: 16),

                          // Marker list
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: markersForView.map((marker) {
                              return Chip(
                                avatar: Icon(
                                  markerTypes[marker.type]?['icon'] ??
                                      Icons.location_on,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                backgroundColor: _parseColor(marker.color),
                                label: Text(
                                  marker.label.isNotEmpty
                                      ? marker.label
                                      : marker.type,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMarkedImage(
    String modelId,
    String view,
    List<BodyMarker> markersForView,
  ) {
    String imagePath;
    if (modelId == 'skin') {
      imagePath = 'assets/png/body_chart_$view.png';
    } else {
      imagePath = 'assets/png/body_chart_${modelId}_$view.png';
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      child: Stack(
        children: [
          // Base image
          Image.asset(
            imagePath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 300,
                alignment: Alignment.center,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Image not available',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          ),

          // Markers overlay
          ...markersForView.map((marker) {
            return Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final x = marker.x * constraints.maxWidth;
                  final y = marker.y * constraints.maxHeight;

                  return Stack(
                    children: [
                      Positioned(
                        left: x - 12,
                        top: y - 24,
                        child: Tooltip(
                          message:
                              '${marker.label}\n${marker.notes.isEmpty ? 'No notes' : marker.notes}',
                          child: Icon(
                            markerTypes[marker.type]?['icon'] as IconData? ??
                                Icons.location_on,
                            color: _parseColor(marker.color),
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  String _getModelTitle(String modelId) {
    switch (modelId) {
      case 'skin':
        return 'Skin (Standard)';
      case 'skeleton':
        return 'Skeleton';
      case 'muscles':
        return 'Muscular System';
      case 'head':
        return 'Head / Brain';
      case 'teeth':
        return 'Dental';
      default:
        return modelId.toUpperCase();
    }
  }
}
