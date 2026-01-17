import 'package:flutter/material.dart';
import 'package:flutter_cube/flutter_cube.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/entities/clinical_report.dart';

/// Option C: Flutter 3D body chart using flutter_cube
class BodyMap3DFlutterWidget extends StatefulWidget {
  final List<BodyMarker> markers;
  final Function(BodyMarker) onMarkerAdded;
  final Function(String) onMarkerRemoved;
  final bool isReadOnly;

  const BodyMap3DFlutterWidget({
    super.key,
    required this.markers,
    required this.onMarkerAdded,
    required this.onMarkerRemoved,
    this.isReadOnly = false,
  });

  @override
  State<BodyMap3DFlutterWidget> createState() => _BodyMap3DFlutterWidgetState();
}

class _BodyMap3DFlutterWidgetState extends State<BodyMap3DFlutterWidget> {
  late Object _model;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      _model = Object(fileName: 'assets/models/human_body.obj');
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading 3D model: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Option C: Flutter 3D (flutter_cube)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const Text('Drag to rotate | Pinch to zoom'),
        Expanded(
          child: Cube(
            onSceneCreated: (Scene scene) {
              scene.world.add(_model);
              scene.camera.zoom = 10;
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Human Figure (OBJ)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Using standard test model "male02.obj".\nReplace with medical-grade model for production.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Tap 3D model to place marker (not yet implemented)'),
                    ),
                  );
                },
                child: const Text('Add Marker (Demo)'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
