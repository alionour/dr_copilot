import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:uuid/uuid.dart';
// Clinical Report Entity
import 'package:dr_copilot/src/features/clinical_reports/domain/entities/clinical_report.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';

/// Option A: WebView-based 3D body chart using three.js
/// implemented with flutter_inappwebview for better Windows support
class BodyMap3DWebViewWidget extends StatefulWidget {
  final List<BodyMarker> markers;
  final Function(BodyMarker) onMarkerAdded;
  final Function(String) onMarkerRemoved;
  final Function(BodyMarker)? onMarkerUpdated; // Add this
  final bool isReadOnly;

  const BodyMap3DWebViewWidget({
    super.key,
    required this.markers,
    required this.onMarkerAdded,
    required this.onMarkerRemoved,
    this.onMarkerUpdated,
    this.isReadOnly = false,
  });

  @override
  State<BodyMap3DWebViewWidget> createState() => _BodyMap3DWebViewWidgetState();
}

class _BodyMap3DWebViewWidgetState extends State<BodyMap3DWebViewWidget> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;

  // Model selection state
  String? _selectedModel; // Null = Show selection screen
  String?
      _selectedSpecialty; // Null = Show specialty list, otherwise show models for this specialty

  // Specialty -> Models mapping with icons and landmarks
  final Map<String, Map<String, dynamic>> _specialties = {
    'General Medicine': {
      'icon': Icons.person_outline,
      'models': [
        {
          'file': 'human_body.glb',
          'name': 'Full Body (Skin)',
          'markerScale': 0.5,
          'landmarks': [
            'Head',
            'Neck',
            'Chest',
            'Abdomen',
            'Back',
            'Left Arm',
            'Right Arm',
            'Left Leg',
            'Right Leg'
          ],
        },
        {
          'file': 'human_muscles.glb',
          'name': 'Muscular System',
          'markerScale': 0.5,
          'landmarks': [
            'Trapezius',
            'Deltoid',
            'Biceps',
            'Triceps',
            'Pectoralis',
            'Latissimus',
            'Rectus Abdominis',
            'Quadriceps',
            'Hamstrings',
            'Gluteus',
            'Gastrocnemius'
          ],
        },
      ],
    },
    'Neurology': {
      'icon': Icons.psychology_outlined,
      'models': [
        {
          'file': 'human_head.glb',
          'name': 'Head / Brain',
          'markerScale': 0.5,
          'landmarks': [
            'Frontal Lobe',
            'Parietal Lobe',
            'Temporal Lobe',
            'Occipital Lobe',
            'Cerebellum',
            'Brainstem',
            'Basal Ganglia',
            'Corpus Callosum',
            'Thalamus',
            'Hypothalamus'
          ],
        },
      ],
    },
    'Orthopedics': {
      'icon': Icons.accessibility_new_outlined,
      'models': [
        {
          'file': 'human_skeleton.glb',
          'name': 'Skeleton',
          'markerScale': 0.5,
          'landmarks': [
            'Cervical (C1-C7)',
            'Thoracic (T1-T12)',
            'Lumbar (L1-L5)',
            'Sacrum',
            'Skull',
            'Clavicle',
            'Scapula',
            'Humerus',
            'Radius',
            'Ulna',
            'Pelvis',
            'Femur',
            'Patella',
            'Tibia',
            'Fibula',
            'Shoulder Joint',
            'Elbow Joint',
            'Hip Joint',
            'Knee Joint',
            'Ankle Joint'
          ],
        },
      ],
    },
    'Dentistry': {
      'icon': Icons.mood_outlined,
      'models': [
        {
          'file': 'human_teeth.glb',
          'name': 'Teeth',
          'markerScale': 0.3,
          'landmarks': [
            'Upper Right (Q1)',
            'Upper Left (Q2)',
            'Lower Left (Q3)',
            'Lower Right (Q4)',
            'Central Incisor',
            'Lateral Incisor',
            'Canine',
            'First Premolar',
            'Second Premolar',
            'First Molar',
            'Second Molar',
            'Third Molar (Wisdom)'
          ],
        },
      ],
    },
  };

  Map<String, dynamic>? _getModelData(String? modelFile) {
    if (modelFile == null) return null;
    for (final specialty in _specialties.values) {
      final models = specialty['models'] as List<Map<String, dynamic>>;
      for (final model in models) {
        if (model['file'] == modelFile) return model;
      }
    }
    return null;
  }

  double _getMarkerScaleForCurrentModel() {
    final modelData = _getModelData(_selectedModel);
    return (modelData?['markerScale'] as double?) ?? 3.0;
  }

  List<String> _getLandmarksForCurrentModel() {
    final modelData = _getModelData(_selectedModel);
    if (modelData == null) return [];
    final landmarks = modelData['landmarks'];
    if (landmarks == null) return [];
    return List<String>.from(landmarks);
  }

  void _addQuickLandmark(String landmarkLabel) {
    if (widget.isReadOnly) return;

    final newMarker = BodyMarker(
      id: const Uuid().v4(),
      x: 0.5, // Center position - user should adjust
      y: 0.5,
      z: 0.0,
      label: landmarkLabel,
      timestamp: DateTime.now(),
      view: '3d',
      type: 'other',
      scale: _getMarkerScaleForCurrentModel(),
      modelId: _selectedModel,
    );

    widget.onMarkerAdded(newMarker);
    setState(() => _selectedMarkerId = newMarker.id);

    // Show toast/snackbar to inform user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "$landmarkLabel" - Click model to position'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Marker types (Duplicated from parent for consistent UI)
  static const Map<String, Map<String, dynamic>> markerTypes = {
    'pain': {'label': 'Pain', 'color': '#D32F2F', 'icon': Icons.location_on},
    'injury': {'label': 'Injury', 'color': '#F57C00', 'icon': Icons.healing},
    'rash': {'label': 'Rash', 'color': '#7B1FA2', 'icon': Icons.bubble_chart},
    'scar': {'label': 'Scar', 'color': '#616161', 'icon': Icons.linear_scale},
    'other': {'label': 'Other', 'color': '#1976D2', 'icon': Icons.location_on},
  };

  String? _selectedMarkerId; // Currently selected marker for editing
  bool _showLandmarkList =
      true; // Toggle for landmark list sidebar - DEFAULT OPEN

  // Per-model interaction mode state
  final Map<String, String> _modelInteractionModes = {}; // Defaults to 'select'

  String get _currentInteractionMode => _selectedModel != null
      ? (_modelInteractionModes[_selectedModel!] ?? 'select')
      : 'select';

  @override
  void didUpdateWidget(covariant BodyMap3DWebViewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.markers != widget.markers) {
      _syncMarkersToJS();
    }
  }

  void _syncMarkersToJS() {
    if (_webViewController == null) return;

    // Sync Interaction Mode to JS on every update to resolve persistence issues
    final currentMode = _currentInteractionMode;
    _webViewController!.callAsyncJavaScript(
        functionBody:
            'if(window.setInteractionMode) window.setInteractionMode("$currentMode");');

    final markersList = widget.markers
        .where((m) =>
            (m.view == '3d' || m.view == 'body') &&
            (m.modelId == _selectedModel ||
                (m.modelId == null && _selectedModel == 'human_body.glb')))
        .map((m) => {
              'id': m.id,
              'x': m.x,
              'y': m.y,
              'z': m.z ?? 0.0,
              'color': m.color,
              'label': m.label,
              'scale': m.scale, // Sync scale
            })
        .toList();

    try {
      _webViewController!.callAsyncJavaScript(
        functionBody: 'window.updateMarkers(markers)',
        arguments: {'markers': markersList},
      );
    } catch (e) {
      // Ignore MissingPluginException - happens on Windows during Hot Restart
      debugPrint('WebView sync error (safe to ignore on Hot Restart): $e');
    }
  }

  Color _parseColor(String hexColor) {
    if (hexColor.isEmpty) return Colors.red;
    try {
      final color = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$color', radix: 16));
    } catch (e) {
      return Colors.red;
    }
  }

  void _updateMarker(BodyMarker updated) {
    if (widget.onMarkerUpdated != null) {
      widget.onMarkerUpdated!(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Landmark List (toggleable)
        if (_showLandmarkList && _selectedModel != null)
          Container(
            width: 280,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey[300]!)),
              color: Colors.grey[50],
            ),
            child: _buildLandmarkList(),
          ),

        // Center: 3D Viewer
        Expanded(
          flex: 3,
          child: _selectedModel == null
              ? _buildModelSelectionScreen()
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // Toggle landmark list button
                              IconButton(
                                icon: Icon(
                                  _showLandmarkList
                                      ? Icons.list
                                      : Icons.list_outlined,
                                  color: _showLandmarkList
                                      ? Theme.of(context).primaryColor
                                      : null,
                                ),
                                onPressed: () {
                                  setState(() =>
                                      _showLandmarkList = !_showLandmarkList);
                                },
                                tooltip: 'Toggle Landmark List',
                              ),
                              const Text(
                                'Option A: WebView 3D',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 16),
                              // Mode Toggle
                              SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(
                                    value: 'select',
                                    icon: Icon(Icons.touch_app),
                                    label: Text('Selection'),
                                  ),
                                  ButtonSegment(
                                    value: 'add',
                                    icon: Icon(Icons.add_location_alt),
                                    label: Text('Interactive'),
                                  ),
                                ],
                                selected: {_currentInteractionMode},
                                onSelectionChanged: (Set<String> newSelection) {
                                  if (_selectedModel != null) {
                                    setState(() {
                                      _modelInteractionModes[_selectedModel!] =
                                          newSelection.first;
                                    });
                                    _webViewController?.callAsyncJavaScript(
                                        functionBody:
                                            'window.setInteractionMode("${newSelection.first}");');
                                  }
                                },
                                style: ButtonStyle(
                                  visualDensity: VisualDensity.compact,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                          // Change Model Button (Replaces Dropdown)
                          Row(
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.grid_view),
                                label: const Text('Change Model'),
                                onPressed: () {
                                  setState(() {
                                    _selectedModel = null;
                                    _selectedMarkerId = null;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              // Quick Landmark Button
                              if (!widget.isReadOnly)
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.bookmark_add_outlined),
                                  tooltip: 'Add Quick Landmark',
                                  onSelected: (landmark) =>
                                      _addQuickLandmark(landmark),
                                  itemBuilder: (context) {
                                    final landmarks =
                                        _getLandmarksForCurrentModel();
                                    return landmarks.map((String landmark) {
                                      return PopupMenuItem<String>(
                                        value: landmark,
                                        child: Row(
                                          children: [
                                            const Icon(Icons.location_on,
                                                size: 18),
                                            const SizedBox(width: 8),
                                            Text(landmark),
                                          ],
                                        ),
                                      );
                                    }).toList();
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          InAppWebView(
                            initialUrlRequest: URLRequest(
                              url: WebUri(
                                  'http://localhost:3000/body_chart_3d.html?model=$_selectedModel&v=${DateTime.now().millisecondsSinceEpoch}'),
                            ),
                            initialSettings: InAppWebViewSettings(
                              isInspectable: true,
                              mediaPlaybackRequiresUserGesture: false,
                              allowsInlineMediaPlayback: true,
                              iframeAllowFullscreen: true,
                              transparentBackground: true,
                            ),
                            onWebViewCreated: (controller) {
                              _webViewController = controller;
                              _setupJavaScriptHandler(controller);
                            },
                            onLoadStop: (controller, url) async {
                              setState(() => _isLoading = false);
                              _syncMarkersToJS();
                            },
                          ),
                          if (_isLoading)
                            const Center(child: CircularProgressIndicator()),

                          // Info text (only when no marker selected)
                          if (_selectedMarkerId == null)
                            Positioned(
                              bottom: 16,
                              left: 16,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Left Click to Add/Select. Drag to Rotate.',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),

        // Right: Sidebar (when marker selected)
        if (_selectedMarkerId != null)
          Container(
            width: 320,
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: Colors.grey[300]!)),
              color: Colors.white,
            ),
            child: _build3DSidebar(),
          ),
      ],
    );
  }

  Widget _buildLandmarkList() {
    final markers3d = widget.markers
        .where((m) =>
            (m.view == '3d' || m.view == 'body') &&
            (m.modelId == _selectedModel ||
                (m.modelId == null && _selectedModel == 'human_body.glb')))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text('Landmarks',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              Text('${markers3d.length} Items',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: markers3d.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                        'No marks added yet.\nClick on the body to add one.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[500])),
                  ),
                )
              : ListView.builder(
                  itemCount: markers3d.length,
                  itemBuilder: (context, index) {
                    final marker = markers3d[index];
                    final isSelected = marker.id == _selectedMarkerId;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _parseColor(marker.color),
                        radius: 12,
                        child: Icon(
                            markerTypes[marker.type]?['icon'] ??
                                Icons.location_on,
                            size: 14,
                            color: Colors.white),
                      ),
                      title: Text(
                          marker.label.isNotEmpty ? marker.label : 'Marker'),
                      subtitle: marker.notes.isNotEmpty
                          ? Text(marker.notes,
                              maxLines: 1, overflow: TextOverflow.ellipsis)
                          : Text(
                              DateFormat('MMM dd, HH:mm')
                                  .format(marker.timestamp),
                              style: const TextStyle(fontSize: 11)),
                      selected: isSelected,
                      selectedTileColor:
                          Theme.of(context).primaryColor.withOpacity(0.1),
                      onTap: () {
                        setState(() => _selectedMarkerId = marker.id);
                        _webViewController?.callAsyncJavaScript(
                            functionBody:
                                'window.setSelectedMarker("${marker.id}");');
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 16),
                        onPressed: () {
                          widget.onMarkerRemoved(marker.id);
                          if (_selectedMarkerId == marker.id) {
                            setState(() => _selectedMarkerId = null);
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _build3DSidebar() {
    final marker = widget.markers.firstWhere(
      (m) => m.id == _selectedMarkerId,
      orElse: () => widget.markers.first,
    );

    // If marker not found, close sidebar
    if (widget.markers.every((m) => m.id != _selectedMarkerId)) {
      Future.microtask(() => setState(() => _selectedMarkerId = null));
      return const SizedBox();
    }

    final notesController = TextEditingController(text: marker.notes);
    notesController.selection = TextSelection.fromPosition(
      TextPosition(offset: marker.notes.length),
    );

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Edit 3D Marker',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() => _selectedMarkerId = null);
                  _webViewController?.callAsyncJavaScript(
                      functionBody: 'window.setSelectedMarker(null);');
                },
                tooltip: 'Close Sidebar',
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Type Selector
              const Text(
                'Condition Type',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: markerTypes.entries.map((entry) {
                  final isSelected = marker.type == entry.key;
                  return ChoiceChip(
                    label: Text(entry.value['label']),
                    selected: isSelected,
                    avatar: Icon(
                      entry.value['icon'],
                      size: 16,
                      color: isSelected ? Colors.white : Colors.grey,
                    ),
                    selectedColor: _parseColor(entry.value['color']),
                    onSelected: (selected) {
                      if (selected) {
                        _updateMarker(marker.copyWith(
                          type: entry.key,
                          label: entry.value['label'],
                          color: entry.value['color'],
                        ));
                      }
                    },
                  );
                }).toList(),
              ),

              const Divider(height: 32),

              // Color Picker
              const Text(
                'Marker Color',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  InkWell(
                    onTap: () async {
                      Color? newColor = await showDialog<Color>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Pick a color'),
                          content: SingleChildScrollView(
                            child: BlockPicker(
                              pickerColor: _parseColor(marker.color),
                              onColorChanged: (color) {
                                Navigator.of(context).pop(color);
                              },
                            ),
                          ),
                        ),
                      );
                      if (newColor != null) {
                        final colorHex =
                            '#${newColor.value.toRadixString(16).substring(2).toUpperCase()}';
                        _updateMarker(marker.copyWith(color: colorHex));
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _parseColor(marker.color),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey),
                      ),
                    ),
                  ),
                  const Text('Tap to change color'),
                ],
              ),

              const Divider(height: 32),

              // Scale Controls
              const Text(
                'Scale',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.remove, size: 18),
                      label: const Text('Smaller'),
                      onPressed: () {
                        _adjustMarkerScale(marker.id, -0.1);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Larger'),
                      onPressed: () {
                        _adjustMarkerScale(marker.id, 0.1);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Position Controls
              const Text(
                'Position',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  // Up button
                  IconButton(
                    icon: const Icon(Icons.arrow_upward),
                    onPressed: () =>
                        _adjustMarkerPosition(marker.id, 0, 0.01, 0),
                    tooltip: 'Move Up',
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Left button
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () =>
                            _adjustMarkerPosition(marker.id, -0.01, 0, 0),
                        tooltip: 'Move Left',
                      ),
                      const SizedBox(width: 32),
                      // Right button
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () =>
                            _adjustMarkerPosition(marker.id, 0.01, 0, 0),
                        tooltip: 'Move Right',
                      ),
                    ],
                  ),
                  // Down button
                  IconButton(
                    icon: const Icon(Icons.arrow_downward),
                    onPressed: () =>
                        _adjustMarkerPosition(marker.id, 0, -0.01, 0),
                    tooltip: 'Move Down',
                  ),
                ],
              ),

              const Divider(height: 32),

              // Notes
              const Text(
                'Observations / Notes',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Describe the condition...',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _updateMarker(marker.copyWith(notes: value));
                },
              ),

              const SizedBox(height: 8),
              Text(
                'Position: (${marker.x.toStringAsFixed(2)}, ${marker.y.toStringAsFixed(2)}, ${marker.z?.toStringAsFixed(2) ?? '0.00'})',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),

        // Footer Actions
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                widget.onMarkerRemoved(marker.id);
                setState(() => _selectedMarkerId = null);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove Marker'),
            ),
          ),
        ),
      ],
    );
  }

  void _adjustMarkerScale(String markerId, double delta) {
    final marker = widget.markers.firstWhere((m) => m.id == markerId);
    final newScale = (marker.scale + delta).clamp(0.1, 5.0);

    _updateMarker(marker.copyWith(scale: newScale));

    // Update in JS
    _webViewController?.callAsyncJavaScript(
      functionBody: '''
        const marker = scene.getObjectByProperty('userData', {id: '$markerId'});
        if (marker) marker.scale.setScalar($newScale);
      ''',
    );
  }

  void _adjustMarkerPosition(String markerId, double dx, double dy, double dz) {
    final marker = widget.markers.firstWhere((m) => m.id == markerId);
    final newX = marker.x + dx;
    final newY = marker.y + dy;
    final newZ = (marker.z ?? 0.0) + dz;

    _updateMarker(marker.copyWith(x: newX, y: newY, z: newZ));

    // Update in JS
    _webViewController?.callAsyncJavaScript(
      functionBody: '''
        const marker = scene.getObjectByProperty('userData', {id: '$markerId'});
        if (marker) {
          marker.position.set($newX, $newY, $newZ);
        }
      ''',
    );
  }

  void _setupJavaScriptHandler(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'onBodyClick',
      callback: (args) async {
        if (widget.isReadOnly) return;
        if (args.isEmpty) return;

        // If we have a selection, clicking body might be deselect (handled in JS),
        // OR it's a valid add if we really clicked empty space.
        // For simplicity, if we are editing, we probably don't want to add immediately?
        // Let's allow it, but deselect current first.
        setState(() => _selectedMarkerId = null);

        final data = args[0] as Map<String, dynamic>;
        final newMarker = BodyMarker(
          id: const Uuid().v4(),
          x: data['x'],
          y: data['y'],
          z: data['z'],
          label: 'New Marker',
          timestamp: DateTime.now(),
          view: '3d',
          scale: _getMarkerScaleForCurrentModel(),
          modelId: _selectedModel, // Associate with current model
        );

        // Instead of dialog, immediately ADD and SELECT it for editing
        widget.onMarkerAdded(newMarker);

        // We need to validly select it after sync.
        // Sync happens in didUpdateWidget.
        // We can optimistically select it.
        setState(() => _selectedMarkerId = newMarker.id);

        // Tell JS to select it (might need slight delay for sync)
        Future.delayed(const Duration(milliseconds: 100), () {
          try {
            controller.callAsyncJavaScript(
                functionBody:
                    "window.addMarker(${newMarker.x}, ${newMarker.y}, ${newMarker.z}, '${newMarker.color}', '${newMarker.id}', ${newMarker.scale}); transformControl.attach(scene.getObjectByProperty('userData', {id: '${newMarker.id}'}));");
          } catch (e) {
            debugPrint('Error adding marker to JS (likely disposed): $e');
          }
        });
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'onMarkerSelected',
      callback: (args) {
        if (args.isNotEmpty) {
          final id = args[0]['id'];
          setState(() => _selectedMarkerId = id);
        }
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'onMarkerDeselected',
      callback: (args) {
        setState(() => _selectedMarkerId = null);
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'onMarkerHover',
      callback: (args) {
        if (args.isNotEmpty) {
          final id = args[0]['id'];
          final marker = widget.markers.firstWhere(
            (m) => m.id == id,
            orElse: () => widget.markers.first,
          );

          // Update tooltip content in JavaScript
          _webViewController?.callAsyncJavaScript(
            functionBody: '''
              window.updateTooltip(
                '${marker.type}',
                '${marker.label}',
                '${marker.notes.replaceAll("'", "\\'")}',
                '${DateFormat('MMM dd, HH:mm').format(marker.timestamp)}'
              );
            ''',
          );
        }
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'onMarkerTransformed',
      callback: (args) {
        if (args.isNotEmpty && widget.onMarkerUpdated != null) {
          final data = args[0];
          final id = data['id'];
          final existing = widget.markers.firstWhere((m) => m.id == id,
              orElse: () => widget.markers.first); // fallback

          final updated = existing.copyWith(
            x: data['x'],
            y: data['y'],
            z: data['z'],
            scale: (data['scale'] as num).toDouble(),
          );
          widget.onMarkerUpdated!(updated);
        }
      },
    );
    // Clean up old handlers
    controller.removeJavaScriptHandler(handlerName: 'onMarkerClick');
  }

  Widget _buildModelSelectionScreen() {
    // Get all models with specialty info for filtering
    final allModels = <Map<String, dynamic>>[];
    for (final entry in _specialties.entries) {
      final specialtyName = entry.key;
      final specialtyData = entry.value;
      final icon = specialtyData['icon'] as IconData;
      final models = specialtyData['models'] as List<Map<String, dynamic>>;
      for (final model in models) {
        allModels.add({
          ...model,
          'specialty': specialtyName,
          'specialtyIcon': icon,
        });
      }
    }

    // Apply filter
    final filteredModels = _selectedSpecialty == null
        ? allModels
        : allModels.where((m) => m['specialty'] == _selectedSpecialty).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select 3D Model',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Filter by specialty or browse all models.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', null),
                const SizedBox(width: 8),
                ..._specialties.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFilterChip(
                        e.key,
                        e.key,
                        icon: e.value['icon'] as IconData,
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Model List
          Expanded(
            child: ListView.builder(
              itemCount: filteredModels.length,
              itemBuilder: (context, index) {
                final model = filteredModels[index];
                final modelFile = model['file'] as String;
                final modelName = model['name'] as String;
                final specialty = model['specialty'] as String;
                final specialtyIcon = model['specialtyIcon'] as IconData;

                // Determine thumbnail
                String imagePath = 'assets/png/thumb_body.png';
                if (modelFile.contains('muscles')) {
                  imagePath = 'assets/png/thumb_muscles.png';
                } else if (modelFile.contains('body')) {
                  imagePath = 'assets/png/thumb_body.png';
                } else if (modelFile.contains('head')) {
                  imagePath = 'assets/png/thumb_brain.png';
                } else if (modelFile.contains('skeleton')) {
                  imagePath = 'assets/png/thumb_skeleton.png';
                } else if (modelFile.contains('teeth')) {
                  imagePath = 'assets/png/thumb_teeth.png';
                }

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  clipBehavior: Clip.antiAlias,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedModel = modelFile;
                        _isLoading = true;
                      });
                      // Removed unsafe _loadModel call - setState triggers rebuild with new URL
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.asset(
                              imagePath,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.accessibility_new,
                                    size: 40, color: Colors.grey[400]);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  modelName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(specialtyIcon,
                                        size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      specialty,
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: Colors.grey[400]),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? filterValue, {IconData? icon}) {
    final isSelected = _selectedSpecialty == filterValue;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon,
                size: 16, color: isSelected ? Colors.white : Colors.blue),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
      onSelected: (_) => setState(() => _selectedSpecialty = filterValue),
      selectedColor: Colors.blue,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
    );
  }
}
