import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class DataStorageSettingsPage extends StatefulWidget {
  const DataStorageSettingsPage({super.key});

  @override
  State<DataStorageSettingsPage> createState() =>
      _DataStorageSettingsPageState();
}

class _DataStorageSettingsPageState extends State<DataStorageSettingsPage> {
  Future<void> _clearAppCache() async {
    // Placeholder for clearing app cache
    // In a real app, you would use path_provider to get the cache directory and delete files
    // or use a package like flutter_cache_manager
    await Future.delayed(const Duration(seconds: 1)); // Simulate work
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('appCacheCleared').tr()),
      );
    }
  }

  Future<void> _exportMyData() async {
    // Placeholder for exporting data
    // In a real app, you would generate a JSON/CSV file of user data and share it
    await Future.delayed(const Duration(seconds: 1)); // Simulate work
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('dataExportStarted').tr()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('dataAndStorage').tr(),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('clearAppCache').tr(),
            leading: const Icon(Icons.cleaning_services),
            onTap: _clearAppCache,
          ),
          const Divider(),
          ListTile(
            title: const Text('exportMyData').tr(),
            leading: const Icon(Icons.download),
            onTap: _exportMyData,
          ),
        ],
      ),
    );
  }
}
