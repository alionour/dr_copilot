import 'package:flutter/material.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/entities/clinical_report.dart';

/// Read-only widget that displays only body map views that have markers.
class BodyMapReadOnlyWidget extends StatelessWidget {
  final List<BodyMarker> markers;
  final bool isGrid;

  const BodyMapReadOnlyWidget({
    super.key,
    required this.markers,
    this.isGrid = false,
  });

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

    // Flatten to list of views for Grid/List display
    final List<Map<String, dynamic>> flatViews = [];
    groupedMarkers.forEach((modelId, views) {
      views.forEach((view, viewMarkers) {
        flatViews.add({
          'modelId': modelId,
          'view': view,
          'markers': viewMarkers,
        });
      });
    });

    if (isGrid) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8, // Optimized to minimize vertical whitespace
        ),
        itemCount: flatViews.length,
        itemBuilder: (context, index) {
          return _buildSingleViewCard(context, flatViews[index]);
        },
      );
    }

    return Column(
      children: flatViews
          .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: _buildSingleViewCard(context, item),
              ))
          .toList(),
    );
  }

  Widget _buildSingleViewCard(BuildContext context, Map<String, dynamic> item) {
    final modelId = item['modelId'] as String;
    final view = item['view'] as String;
    final markersForView = item['markers'] as List<BodyMarker>;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: Model - View
            Text(
              '${_getModelTitle(modelId)} - ${viewTitles[view] ?? view}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Image
            Align(
              alignment: Alignment.topCenter,
              child: _buildMarkedImage(modelId, view, markersForView),
            ),

            const SizedBox(height: 8),
            // Marker Chips (Limited to prevent overflow in grid)
            SizedBox(
              height: 32, // Fixed height for chips row
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: markersForView.map((marker) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Chip(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      avatar: Icon(
                        markerTypes[marker.type]?['icon'] ?? Icons.location_on,
                        size: 14,
                        color: Colors.white,
                      ),
                      backgroundColor: _parseColor(marker.color),
                      label: Text(
                        marker.label.isNotEmpty ? marker.label : marker.type,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  );
                }).toList(),
              ),
            )
          ],
        ),
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

    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 4.0,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Stack(
          children: [
            Image.asset(
              imagePath,
              // No explicit fit or size, allowing intrinsic dimensions.
              // FittedBox will scale the intrinsic result to fit the parent.
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox(
                    width: 300,
                    height: 400,
                    child: Center(
                        child: Icon(Icons.broken_image,
                            color: Colors.grey, size: 50)));
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
                            message: '${marker.label}\n${marker.notes}',
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
