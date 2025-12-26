import 'package:dr_copilot/src/features/navigation_side/presentation/widgets/nav_menu_button.dart';
import 'package:dr_copilot/src/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
// import 'package:dr_copilot/src/features/admin/presentation/pages/admin_migration_page.dart'; // REMOVED

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
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return ListView(
            children: <Widget>[
              _buildSectionHeader('general'),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text('language'.tr()),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: state.localeCode,
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
                      // ... (Keep other languages if needed, omitted for brevity but standard logic applies)
                      DropdownMenuItem(
                        value: 'es',
                        child: Text('language_es'.tr()),
                      ),
                      DropdownMenuItem(
                        value: 'fr',
                        child: Text('language_fr'.tr()),
                      ),
                      DropdownMenuItem(
                        value: 'de',
                        child: Text('language_de'.tr()),
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
              _buildSectionHeader('Copilot Intelligence'),
              ListTile(
                leading: const Icon(Icons.psychology),
                title: const Text('Copilot Preferences'),
                subtitle: const Text(
                    'Configure required fields for AI (Patients, Sessions, Evaluations)'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => context.push('/settings/copilot_preferences'),
              ),
              _buildSectionHeader('appSettings'),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: Text('notifications'.tr()),
                onTap: () => context.push('/settings/notifications'),
              ),
              ListTile(
                leading: const Icon(Icons.date_range),
                title: Text('Calendar Settings'),
                onTap: () => context.push('/settings/calendar_settings'),
              ),
              ListTile(
                leading: const Icon(Icons.storage),
                title: Text('dataAndStorage'.tr()),
                onTap: () => context.push('/settings/data_storage'),
              ),
              _buildSectionHeader('accountAndSecurity'),
              ListTile(
                leading: const Icon(Icons.card_membership),
                title: Text('subscriptionAndBilling'.tr()),
                onTap: () => context.push('/settings/subscription'),
              ),
              ListTile(
                leading: const Icon(Icons.security),
                title: Text('security'.tr()),
                onTap: () => context.push('/settings/security'),
              ),
              ListTile(
                leading: const Icon(Icons.model_training),
                title: Text('aiModel'.tr()),
                onTap: () => context.push('/settings/model_selection'),
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
          );
        },
      ),
    );
  }
}
