import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/entities/clinical_report.dart';

class BodyMapWidget extends StatefulWidget {
  final List<BodyMarker> markers;
  final Function(BodyMarker) onMarkerAdded;
  final Function(String) onMarkerRemoved;
  final bool isReadOnly;

  const BodyMapWidget({
    super.key,
    required this.markers,
    required this.onMarkerAdded,
    required this.onMarkerRemoved,
    this.isReadOnly = false,
  });

  @override
  State<BodyMapWidget> createState() => _BodyMapWidgetState();
}

class _BodyMapWidgetState extends State<BodyMapWidget> {
  // Use a key to get the size of the image container
  final GlobalKey _imageKey = GlobalKey();

  void _handleTap(TapUpDetails details) {
    if (widget.isReadOnly) return;

    final RenderBox? renderBox =
        _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final size = renderBox.size;

    final dx = localPosition.dx / size.width;
    final dy = localPosition.dy / size.height;

    // Create a new marker
    final marker = BodyMarker(
      id: const Uuid().v4(),
      x: dx,
      y: dy,
      label: 'New Marker',
      type: 'pain',
    );

    widget.onMarkerAdded(marker);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InteractiveViewer(
        minScale: 1.0,
        maxScale: 4.0,
        child: SingleChildScrollView(
          child: Stack(
            children: [
              GestureDetector(
                onTapUp: _handleTap,
                child: Container(
                  key: _imageKey,
                  constraints: const BoxConstraints(
                    maxHeight: 600, // Reasonable height constraint
                  ),
                  child: Image.asset(
                    'assets/png/body_chart_template.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              ...widget.markers.map((marker) {
                return Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // We need to access the image size again or rely on Positioned relative to Stack.
                      // But the Stack size is determined by the Image Container (biggest child).
                      // So Positioned(left, top) should work if we calculate pixel values.

                      // Wait, Positioned(left, top) needs pixel values.
                      // Converting relative (0.0-1.0) back to pixels requires knowing constraints.maxWidth/maxHeight.
                      // Since we are inside Positioned.fill -> LayoutBuilder, 'constraints' gives the size of the Stack!

                      final x = marker.x * constraints.maxWidth;
                      final y = marker.y * constraints.maxHeight;

                      return Stack(
                        children: [
                          Positioned(
                            left: x - 12, // Center the icon (assuming 24px)
                            top: y - 24, // Bottom tip at the point
                            child: GestureDetector(
                              onTap: () {
                                if (!widget.isReadOnly) {
                                  widget.onMarkerRemoved(marker.id);
                                }
                              },
                              child: Tooltip(
                                message: marker.type,
                                child: Icon(
                                  Icons.location_on,
                                  color: Colors.red.shade700,
                                  size: 24,
                                ),
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
      ),
    );
  }
}
