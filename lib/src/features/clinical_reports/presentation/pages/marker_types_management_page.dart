import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/entities/marker_type.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/services/marker_types_service.dart';

/// Simple management page - clinicId passed via routing
class MarkerTypesManagementPage extends StatefulWidget {
  final String clinicId;

  const MarkerTypesManagementPage({super.key, required this.clinicId});

  @override
  State<MarkerTypesManagementPage> createState() =>
      _MarkerTypesManagementPageState();
}

class _MarkerTypesManagementPageState extends State<MarkerTypesManagementPage> {
  final MarkerTypesService _service = MarkerTypesService();
  List<MarkerType> _allTypes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  Future<void> _loadTypes() async {
    setState(() => _isLoading = true);
    try {
      final types = await _service.getAllTypes(widget.clinicId);
      setState(() {
        _allTypes = types;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: SelectionArea(child: Text('errorMessage'.tr(args: [e.toString()])))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('bodyChartMarkerTypes').tr()),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('builtInTypes'.tr(),
                    style:
                        const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('defaultMarkerTypesDescription'.tr(),
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                ..._allTypes.where((t) => t.isBuiltIn).map(_buildTypeCard),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('customTypes'.tr(),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      onPressed: () => _showAddEditDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('addCustomType').tr(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_allTypes.where((t) => !t.isBuiltIn).isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'noCustomTypesDescription'.tr(),
                        style: const TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ..._allTypes.where((t) => !t.isBuiltIn).map(_buildTypeCard),
              ],
            ),
    );
  }

  Widget _buildTypeCard(MarkerType type) {
    final color = _parseColor(type.color);
    final icon = IconData(type.iconCodePoint, fontFamily: type.iconFontFamily);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(type.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(type.isBuiltIn ? 'builtIn'.tr() : 'custom'.tr()),
        trailing: type.isBuiltIn
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showAddEditDialog(context, type),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(type),
                  ),
                ],
              ),
      ),
    );
  }

  Color _parseColor(String hexColor) {
    final color = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$color', radix: 16));
  }

  void _showAddEditDialog(BuildContext context, [MarkerType? existing]) {
    showDialog(
      context: context,
      builder: (context) => _AddEditDialog(
        clinicId: widget.clinicId,
        existing: existing,
        onSave: _loadTypes,
      ),
    );
  }

  Future<void> _confirmDelete(MarkerType type) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('deleteMarkerType').tr(),
        content: SelectionArea(child: Text('deleteMarkerTypeConfirmation'.tr(args: [type.name]))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('cancel').tr()),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('delete').tr(),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _service.deleteCustomType(widget.clinicId, type.id);
        _loadTypes();
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: SelectionArea(child: Text('delete'.tr()))));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: SelectionArea(child: Text('errorMessage'.tr(args: [e.toString()])))));
        }
      }
    }
  }
}

class _AddEditDialog extends StatefulWidget {
  final String clinicId;
  final MarkerType? existing;
  final VoidCallback onSave;

  const _AddEditDialog(
      {required this.clinicId, this.existing, required this.onSave});

  @override
  State<_AddEditDialog> createState() => _AddEditDialogState();
}

class _AddEditDialogState extends State<_AddEditDialog> {
  late TextEditingController _nameController;
  late int _selectedIconCodePoint;
  late Color _selectedColor;
  final _service = MarkerTypesService();

  static const icons = [
    Icons.location_on,
    Icons.healing,
    Icons.bubble_chart,
    Icons.favorite,
    Icons.local_hospital,
    Icons.medication,
    Icons.water_drop,
    Icons.star,
    Icons.circle,
    Icons.square,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _selectedIconCodePoint =
        widget.existing?.iconCodePoint ?? Icons.location_on.codePoint;
    _selectedColor = widget.existing != null
        ? _parseColor(widget.existing!.color)
        : Colors.red;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color _parseColor(String hex) =>
      Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
  String _colorToHex(Color c) =>
      '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'addType'.tr() : 'editType'.tr()),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                  labelText: 'name'.tr(), border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            Text('icon'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(
              height: 120,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5, mainAxisSpacing: 8, crossAxisSpacing: 8),
                itemCount: icons.length,
                itemBuilder: (context, i) {
                  final isSelected =
                      icons[i].codePoint == _selectedIconCodePoint;
                  return InkWell(
                    onTap: () => setState(
                        () => _selectedIconCodePoint = icons[i].codePoint),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: isSelected ? _selectedColor : Colors.grey,
                            width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icons[i], color: _selectedColor),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text('color'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('pickColor').tr(),
                  content: ColorPicker(
                      pickerColor: _selectedColor,
                      onColorChanged: (c) =>
                          setState(() => _selectedColor = c)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('save').tr())
                  ],
                ),
              ),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                    color: _selectedColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey)),
                child: Center(
                    child: Text(_colorToHex(_selectedColor),
                        style: TextStyle(
                            color: _selectedColor.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                            fontWeight: FontWeight.bold))),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('cancel').tr()),
        FilledButton(onPressed: _save, child: const Text('save').tr()),
      ],
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: SelectionArea(child: Text('enterName'.tr()))));
      return;
    }

    try {
      final exists = await _service.typeNameExists(widget.clinicId, name,
          excludeId: widget.existing?.id);
      if (exists && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: SelectionArea(child: Text('nameExists'.tr()))));
        return;
      }

      final type = MarkerType(
          id: widget.existing?.id ?? '',
          name: name,
          iconCodePoint: _selectedIconCodePoint,
          color: _colorToHex(_selectedColor));

      if (widget.existing == null) {
        await _service.saveCustomType(widget.clinicId, type);
      } else {
        await _service.updateCustomType(
            widget.clinicId, widget.existing!.id, type);
      }

      widget.onSave();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: SelectionArea(child: Text(widget.existing == null ? 'added'.tr() : 'updated'.tr()))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: SelectionArea(child: Text('errorMessage'.tr(args: [e.toString()])))));
      }
    }
  }
}
