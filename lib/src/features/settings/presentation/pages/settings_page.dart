import 'package:dr_copilot/src/core/app/notifiers/theme_notifier.dart';
import 'package:dr_copilot/src/features/navigation_side/presentation/widgets/nav_menu_button.dart';
import 'package:dr_copilot/src/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    context.read<SettingsBloc>().add(LoadSettingsEvent());
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
    final navMenuButton = NavMenuButtonProvider.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr()),
        leading: const Icon(Icons.settings),
        actions: [navMenuButton ?? const SizedBox()],
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0.5,
      ),
      body: ListView(
        children: <Widget>[
          _buildSectionHeader('general'),
          BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, state) {
              return ListTile(
                leading: const Icon(Icons.color_lens),
                title: Text(
                  state is SettingsDarkMode
                      ? 'lightMode'.tr()
                      : 'darkMode'.tr(),
                ),
                onTap: () {
                  context.read<SettingsBloc>().add(ToggleThemeEvent());
                  context.read<ThemeNotifier>().toggleTheme();
                },
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text('language'.tr()),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: context.locale.languageCode,
                onChanged: (String? newLocale) {
                  if (newLocale != null) {
                    context.read<SettingsBloc>().add(
                      ChangeLocaleEvent(newLocale),
                    );
                    context.setLocale(Locale(newLocale));
                  }
                },
                items: [
                  DropdownMenuItem(
                    value: 'en',
                    child: Row(
                      children: [
                        Icon(Icons.language, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('language_en'.tr()),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'ar',
                    child: Row(
                      children: [
                        Icon(Icons.language, color: Colors.green),
                        SizedBox(width: 8),
                        Text('language_ar'.tr()),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'es',
                    child: Row(
                      children: [
                        Icon(Icons.language, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('language_es'.tr()),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'fr',
                    child: Row(
                      children: [
                        Icon(Icons.language, color: Colors.purple),
                        SizedBox(width: 8),
                        Text('language_fr'.tr()),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'de',
                    child: Row(
                      children: [
                        Icon(Icons.language, color: Colors.red),
                        SizedBox(width: 8),
                        Text('language_de'.tr()),
                      ],
                    ),
                  ),
                ],
                dropdownColor: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.palette),
            title: Text('appearance'.tr()),
            onTap: () => context.push('/settings/appearance'),
          ),
          _buildSectionHeader('appSettings'),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: Text('notifications'.tr()),
            onTap: () => context.push('/settings/notifications'),
          ),
          ListTile(
            leading: const Icon(Icons.storage),
            title: Text('dataAndStorage'.tr()),
            onTap: () => context.push('/settings/data_storage'),
          ),
          _buildSectionHeader('accountAndSecurity'),
          ListTile(
            leading: const Icon(Icons.security),
            title: Text('security'.tr()),
            onTap: () => context.push('/settings/security'),
          ),
          ListTile(
            leading: const Icon(Icons.vpn_key),
            title: Text('openAIApiKey'.tr()),
            onTap: () => context.push('/settings/api_key?from=settings'),
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: Text('privacy'.tr()),
            onTap: () => context.push('/privacy'),
          ),
          _buildSectionHeader('support'),
          ListTile(
            leading: const Icon(Icons.help),
            title: Text('helpSupport'.tr()),
            onTap: () => context.push('/help_support'),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text('about'.tr()),
            onTap: () => context.push('/about'),
          ),
        ],
      ),
    );
  }
}
