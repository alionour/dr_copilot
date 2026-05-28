import 'package:dr_copilot/src/core/app/notifiers/theme_notifier.dart';
import 'package:dr_copilot/src/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

class AppearanceSettingsPage extends StatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  State<AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String _fontSize = 'medium';
  bool _isLoading = true;

  // Available color schemes with user-friendly names
  final Map<FlexScheme, String> _colorSchemes = {
    FlexScheme.tealM3: 'colorTeal',
    FlexScheme.blue: 'colorBlue',
    FlexScheme.indigo: 'colorIndigo',
    FlexScheme.deepPurple: 'colorDeepPurple',
    FlexScheme.red: 'colorRed',
    FlexScheme.hippieBlue: 'colorHippieBlue',
    FlexScheme.amber: 'colorAmber',
    FlexScheme.green: 'colorGreen',
    FlexScheme.blueWhale: 'colorBlueWhale',
    FlexScheme.sakura: 'colorSakura',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final fontSize = await _secureStorage.read(key: 'fontSize');

    if (mounted) {
      setState(() {
        _fontSize = fontSize ?? 'medium';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSetting(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  Widget _buildSectionHeader(String titleKey) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        titleKey.tr(),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('appearance').tr()),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildSectionHeader('themeMode'),
                BlocBuilder<SettingsBloc, SettingsState>(
                  builder: (context, state) {
                    final isDarkMode = state.isDarkMode;
                    return SwitchListTile(
                      title: const Text('darkMode').tr(),
                      subtitle: Text(
                        isDarkMode
                            ? 'darkModeDescription'.tr()
                            : 'lightModeDescription'.tr(),
                      ),
                      value: isDarkMode,
                      onChanged: (bool value) {
                        context.read<SettingsBloc>().add(ToggleThemeEvent());
                        themeNotifier.toggleTheme();
                      },
                      secondary: Icon(
                        isDarkMode
                            ? Icons.dark_mode_outlined
                            : Icons.light_mode_outlined,
                      ),
                    );
                  },
                ),
                _buildSectionHeader('colorScheme'),
                ListTile(
                  title: const Text('colorScheme').tr(),
                  subtitle: Text(
                    _colorSchemes[themeNotifier.currentScheme]?.tr() ??
                        'colorTeal'.tr(),
                  ),
                  leading: const Icon(Icons.palette_outlined),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showColorSchemeDialog(themeNotifier),
                ),
                _buildSectionHeader('textSize'),
                ListTile(
                  title: const Text('fontSize').tr(),
                  subtitle: Text(_fontSize.tr()),
                  leading: const Icon(Icons.text_fields),
                  trailing: DropdownButton<String>(
                    value: _fontSize,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _fontSize = newValue;
                        });
                        _updateSetting('fontSize', newValue);
                        themeNotifier.updateFontSize(newValue);
                      }
                    },
                    items: <String>['small', 'medium', 'large']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value).tr(),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
    );
  }

  void _showColorSchemeDialog(ThemeNotifier themeNotifier) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('selectColorScheme').tr(),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _colorSchemes.length,
              itemBuilder: (context, index) {
                final scheme = _colorSchemes.keys.elementAt(index);
                final schemeName = _colorSchemes[scheme]!;
                final isSelected = themeNotifier.currentScheme == scheme;

                // Get a sample color from the scheme
                final sampleColor = themeNotifier.isDarkMode
                    ? FlexColorScheme.dark(scheme: scheme).toTheme.primaryColor
                    : FlexColorScheme.light(
                        scheme: scheme,
                      ).toTheme.primaryColor;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: sampleColor,
                    radius: 16,
                  ),
                  title: Text(schemeName).tr(),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle_outline,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: () async {
                    themeNotifier.updateScheme(scheme);
                    await _updateSetting('themeScheme', scheme.name);
                    if (context.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('cancel').tr(),
            ),
          ],
        );
      },
    );
  }
}
