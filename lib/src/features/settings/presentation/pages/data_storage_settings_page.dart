import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

class DataStorageSettingsPage extends StatefulWidget {
  const DataStorageSettingsPage({super.key});

  @override
  State<DataStorageSettingsPage> createState() =>
      _DataStorageSettingsPageState();
}

class _DataStorageSettingsPageState extends State<DataStorageSettingsPage> {
  Future<void> _clearAppCache() async {
    try {
      if (!mounted) return;
      setState(() {
        // You might want to show a loading indicator here if needed
      });

      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: SelectionArea(child: Text('appCacheCleared').tr())));
      }
    } catch (e) {
      debugPrint('Error clearing cache: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: SelectionArea(
                  child: Text('errorClearingCache'.tr(args: [e.toString()])))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('dataAndStorage').tr()),
      body: ListView(
        children: [
          ListTile(
            title: const Text('clearAppCache').tr(),
            leading: const Icon(Icons.cleaning_services_outlined),
            onTap: _clearAppCache,
          ),
          const Divider(),
          ListTile(
            title: const Text('exportMyData').tr(),
            subtitle: const Text('exportMyDataDescription').tr(),
            leading: const Icon(Icons.download_outlined),
            onTap: () => context.push('/settings/export_data'),
          ),
        ],
      ),
    );
  }
}
