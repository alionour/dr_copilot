import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
// import 'package:dr_copilot/src/features/clinical_reports/presentation/widgets/body_map_3d_webview_widget.dart'; // Removed
import 'package:dr_copilot/src/features/clinical_reports/domain/entities/clinical_report.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class BodyMapWidget extends StatefulWidget {
  final List<BodyMarker> markers;
  final Function(BodyMarker) onMarkerAdded;
  final Function(String) onMarkerRemoved;
  final Function(BodyMarker)? onMarkerUpdated;
  final bool isReadOnly;

  const BodyMapWidget({
    super.key,
    required this.markers,
    required this.onMarkerAdded,
    required this.onMarkerRemoved,
    this.onMarkerUpdated,
    this.isReadOnly = false,
  });

  @override
  State<BodyMapWidget> createState() => _BodyMapWidgetState();
}

class _BodyMapWidgetState extends State<BodyMapWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _pulseController; // For selected marker animation
  final GlobalKey _imageKey = GlobalKey();
  String _currentView = 'front';

  static const Map<String, String> viewTitles = {
    'front': 'Front',
    'back': 'Back',
    'lateral': 'Lateral',
  };

  // Marker type configurations with colors
  static const Map<String, Map<String, dynamic>> markerTypes = {
    'pain': {'label': 'Pain', 'color': '#D32F2F', 'icon': Icons.location_on},
    'injury': {'label': 'Injury', 'color': '#F57C00', 'icon': Icons.healing},
    'rash': {'label': 'Rash', 'color': '#7B1FA2', 'icon': Icons.bubble_chart},
    'scar': {'label': 'Scar', 'color': '#616161', 'icon': Icons.linear_scale},
    'other': {'label': 'Other', 'color': '#1976D2', 'icon': Icons.location_on},
  };

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Color _parseColor(String hexColor) {
    final color = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$color', radix: 16));
  }

  String? _selectedMarkerId;
  bool _showLandmarkList = true;

  // Model Selection
  String _selectedModel = 'skin';
  final Map<String, String> _models = {
    'skin': 'Skin (Standard)',
    'skeleton': 'Skeleton',
    'muscles': 'Muscles',
    'head': 'Head / Brain',
    'teeth': 'Teeth',
  };

  // Views configuration per model
  static const Map<String, List<String>> _modelViews = {
    'skin': ['front', 'back', 'lateral'],
    'skeleton': ['front', 'back', 'lateral'],
    'muscles': ['front', 'back', 'lateral'],
    'head': ['lateral'],
    'teeth': ['front'],
  };

  @override
  void initState() {
    super.initState();
    _initTabController();

    // Initialize pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  void _initTabController() {
    final availableViews = _modelViews[_selectedModel] ?? ['front'];
    _tabController = TabController(length: availableViews.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentView = availableViews[_tabController.index];
        });
      }
    });

    // Ensure current view is valid for new model, else reset to first available
    if (!availableViews.contains(_currentView)) {
      _currentView = availableViews.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableViews = _modelViews[_selectedModel] ?? ['front'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ... (Leading Drawer unchanged)
        if (_showLandmarkList)
          Container(
            width: 280,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey[300]!)),
              color: Colors.grey[50],
            ),
            child: _buildLandmarkList(),
          ),

        // Center: Body Map
        Expanded(
          flex: 3,
          child: Column(
            children: [
              // Top Bar: Model & View Selection
              Container(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Model Selector
                    Row(
                      children: [
                        const SizedBox(width: 8),
                        Text('Model:',
                            style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        DropdownButton<String>(
                          value: _selectedModel,
                          underline: const SizedBox(),
                          style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 15),
                          onChanged: (value) {
                            if (value != null && value != _selectedModel) {
                              setState(() {
                                _selectedModel = value;
                                _selectedMarkerId = null;
                                _tabController.dispose();
                                _initTabController();
                              });
                            }
                          },
                          items: _models.entries
                              .map((e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(e.value),
                                  ))
                              .toList(),
                        ),
                        // ... (Spacer and icon buttons unchanged)
                        const Spacer(),
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
                              setState(
                                  () => _showLandmarkList = !_showLandmarkList);
                            },
                            tooltip: 'Toggle Landmark List'),
                      ],
                    ),
                    const Divider(height: 1),
                    // View Selector (Dynamic)
                    TabBar(
                      controller: _tabController,
                      isScrollable: false,
                      labelColor: Theme.of(context).primaryColor,
                      unselectedLabelColor: Colors.grey,
                      indicatorSize: TabBarIndicatorSize.tab,
                      onTap: (index) {
                        setState(() {
                          _currentView = availableViews[index];
                          _selectedMarkerId = null;
                        });
                      },
                      tabs: availableViews.map((view) {
                        IconData icon;
                        switch (view) {
                          case 'front':
                            icon = Icons.accessibility_new;
                            break;
                          case 'back':
                            icon = Icons.accessibility;
                            break;
                          case 'lateral':
                            icon = Icons.directions_walk;
                            break;
                          default:
                            icon = Icons.image;
                        }
                        return Tab(
                            text: viewTitles[view] ?? view, icon: Icon(icon));
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // Body Chart Area
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Click on background to deselect
                    if (_selectedMarkerId != null) {
                      setState(() => _selectedMarkerId = null);
                    }
                  },
                  child: TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: availableViews
                        .map((view) => _buildViewWidget(view))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Right Side: Sidebar (Visible when marker selected)
        if (_selectedMarkerId != null)
          Container(
            width: 320,
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: Colors.grey[300]!)),
              color: Colors.white,
            ),
            child: _buildSidebar(),
          ),
      ],
    );
  }

  Widget _buildLandmarkList() {
    final availableViews = _modelViews[_selectedModel] ?? ['front'];

    final markers2d = widget.markers.where((m) {
      final matchesModel = m.modelId == _selectedModel ||
          (m.modelId == null && _selectedModel == 'skin');
      return matchesModel && availableViews.contains(m.view);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text('Landmarks',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              Text('${markers2d.length} Items',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: markers2d.isEmpty
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
                  itemCount: markers2d.length,
                  itemBuilder: (context, index) {
                    final marker = markers2d[index];
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
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(viewTitles[marker.view] ?? marker.view,
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold)),
                          if (marker.notes.isNotEmpty)
                            Text(marker.notes,
                                maxLines: 1, overflow: TextOverflow.ellipsis)
                          else
                            Text(
                                DateFormat('MMM dd, HH:mm')
                                    .format(marker.timestamp),
                                style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                      selected: isSelected,
                      selectedTileColor:
                          Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      onTap: () {
                        setState(() {
                          _selectedMarkerId = marker.id;
                          // Also switch view to the marker's view if needed
                          if (availableViews.contains(marker.view)) {
                            _currentView = marker.view;
                            _tabController
                                .animateTo(availableViews.indexOf(marker.view));
                          }
                        });
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

  Widget _buildSidebar() {
    final marker = widget.markers.firstWhere(
      (m) => m.id == _selectedMarkerId,
      orElse: () => widget.markers.first, // Should not happen if logic correct
    );

    // If marker not found (deleted?), close sidebar
    if (widget.markers.every((m) => m.id != _selectedMarkerId)) {
      // Schedule microtask to avoid build error
      Future.microtask(() => setState(() => _selectedMarkerId = null));
      return const SizedBox();
    }

    // Controllers for editing
    final notesController = TextEditingController(text: marker.notes);
    // Move cursor to end
    notesController.selection =
        TextSelection.fromPosition(TextPosition(offset: marker.notes.length));

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Edit Marker',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selectedMarkerId = null),
                tooltip: 'Close Sidebar',
              )
            ],
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Type Selector
              const Text('Condition Type',
                  style: TextStyle(fontWeight: FontWeight.bold)),
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
                          color: entry
                              .value['color'], // Reset color to type default
                        ));
                      }
                    },
                  );
                }).toList(),
              ),

              const Divider(height: 32),

              // Color Picker
              const Text('Marker Color',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  InkWell(
                    onTap: () async {
                      // Show Color Picker Dialog
                      // We import flutter_colorpicker at top
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
                            '#${newColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
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

              // Notes
              const Text('Observations / Notes',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Describe the condition...',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  // Throttle or direct update?
                  // Direct update is okay for standard text fields in flutter
                  _updateMarker(marker.copyWith(notes: value));
                },
              ),

              const SizedBox(height: 8),
              Text(
                'Created: ${DateFormat('MMM dd, HH:mm').format(marker.timestamp)}',
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
                  padding: const EdgeInsets.symmetric(vertical: 16)),
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

  void _updateMarker(BodyMarker updated) {
    if (widget.onMarkerUpdated != null) {
      widget.onMarkerUpdated!(updated);
    }
  }

  Widget _buildViewWidget(String view) {
    // Filter markers by view AND model
    final viewMarkers = widget.markers.where((m) {
      final matchesView = m.view == view;
      final matchesModel = m.modelId == _selectedModel ||
          (m.modelId == null && _selectedModel == 'skin');
      return matchesView && matchesModel;
    }).toList();

    // Construct image path based on model
    // e.g. body_chart_front.png (skin)
    // e.g. body_chart_skeleton_front.png
    String imagePath;
    if (_selectedModel == 'skin') {
      imagePath = 'assets/png/body_chart_$view.png';
    } else {
      // Use standard naming: body_chart_skeleton_front.png
      // Note: We might not have back/left/right for all models, will rely on errorBuilder
      imagePath = 'assets/png/body_chart_${_selectedModel}_$view.png';
    }

    return Center(
      child: InteractiveViewer(
        minScale: 1.0,
        maxScale: 4.0,
        child: SingleChildScrollView(
          child: Stack(
            children: [
              // Realistic PNG image as base
              GestureDetector(
                onTapUp: _handleTap,
                child: Container(
                  key: view == _currentView ? _imageKey : null,
                  constraints: const BoxConstraints(maxHeight: 600),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to Main Template or Placeholder text
                      return Container(
                        height: 400,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.image_not_supported,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text('View not available for $_selectedModel',
                                style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Markers overlay
              ...viewMarkers.map((marker) {
                return Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final x = marker.x * constraints.maxWidth;
                      final y = marker.y * constraints.maxHeight;

                      return Stack(
                        children: [
                          if (marker.id == _selectedMarkerId)
                            Positioned(
                              left: x - 20, // Center the larger ring (44px)
                              top: y - 32, // Center relative to icon tip
                              child: AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  return Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _parseColor(marker.color)
                                            .withValues(
                                                alpha: 1.0 -
                                                    _pulseController.value),
                                        width: 4 * _pulseController.value,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          Positioned(
                            left: x - 12,
                            top: y - 24,
                            child: GestureDetector(
                              onTap: () => _handleMarkerTap(marker),
                              child: Tooltip(
                                message:
                                    '${marker.label}\n${marker.type.toUpperCase()}\n${marker.notes.isEmpty ? 'No notes' : marker.notes}\n${DateFormat('MMM dd, yyyy HH:mm').format(marker.timestamp)}',
                                child: Icon(
                                  markerTypes[marker.type]?['icon']
                                          as IconData? ??
                                      Icons.location_on,
                                  color: _parseColor(marker.color),
                                  size: 28,
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

  void _handleTap(TapUpDetails details) async {
    if (widget.isReadOnly) return;

    final RenderBox? renderBox =
        _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final size = renderBox.size;

    final dx = localPosition.dx / size.width;
    final dy = localPosition.dy / size.height;

    // Create New Marker
    final newMarker = BodyMarker(
      id: const Uuid().v4(),
      x: dx,
      y: dy,
      label: 'New Marker',
      type: 'pain', // Default
      timestamp: DateTime.now(),
      view: _currentView,
      modelId: _selectedModel == 'skin'
          ? null
          : _selectedModel, // Standardize null for legacy skin
    );

    // Add it immediately
    widget.onMarkerAdded(newMarker);

    // Select it to open sidebar
    setState(() {
      _selectedMarkerId = newMarker.id;
    });
  }

  void _handleMarkerTap(BodyMarker marker) {
    if (widget.isReadOnly) {
      _showMarkerInfoDialog(context, marker);
    } else {
      // Select to open sidebar
      setState(() {
        _selectedMarkerId = marker.id;
      });
    }
  }

  void _showMarkerInfoDialog(BuildContext context, BodyMarker marker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              markerTypes[marker.type]?['icon'] as IconData? ??
                  Icons.location_on,
              color: _parseColor(marker.color),
            ),
            const SizedBox(width: 8),
            Text(markerTypes[marker.type]?['label'] as String? ?? marker.type),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (marker.notes.isNotEmpty) ...[
              const Text('Notes:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(marker.notes),
              const SizedBox(height: 12),
            ],
            const Text('View:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(viewTitles[marker.view] ?? marker.view),
            const SizedBox(height: 12),
            const Text('Timestamp:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(DateFormat('MMM dd, yyyy HH:mm').format(marker.timestamp)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
