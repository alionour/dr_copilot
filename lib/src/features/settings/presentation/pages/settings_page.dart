import 'package:dr_copilot/src/features/navigation_side/presentation/widgets/nav_menu_button.dart';
import 'package:dr_copilot/src/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart'; // For defaultTargetPlatform
import 'dart:convert'; // For jsonEncode
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';

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

  Future<void> _openPresentationWindow() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.windows &&
            defaultTargetPlatform != TargetPlatform.linux &&
            defaultTargetPlatform != TargetPlatform.macOS)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not supported on this platform')),
      );
      return;
    }

    try {
      final window = await WindowController.create(WindowConfiguration(
        arguments: jsonEncode({
          'args1': 'SubWindow',
          'args2': 100,
          'args3': true,
        }),
      ));

      // Window sizing/centering must be done by the window itself in 0.3.0+
      // or via platform channels if needed.
      await window.show();
    } catch (e) {
      debugPrint('Error opening window: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening window: $e')),
        );
      }
    }
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
        leading: const Icon(Icons.settings_outlined),
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
                leading: const Icon(Icons.language_outlined),
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
                            Icon(Icons.language_outlined, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('language_en'.tr()),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'ar',
                        child: Row(
                          children: [
                            Icon(Icons.language_outlined, color: Colors.green),
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
                leading: const Icon(Icons.palette_outlined),
                title: Text('appearance'.tr()),
                onTap: () => context.push('/settings/appearance'),
              ),
              if (OwnerNotifier().hasPermission(AppPermission.editSettings)) ...[
                _buildSectionHeader('Copilot Intelligence'),
                ListTile(
                  leading: const Icon(Icons.psychology_outlined),
                  title: const Text('Copilot Preferences'),
                  subtitle: const Text(
                      'Configure required fields for AI (Patients, Sessions, Evaluations)'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.push('/settings/copilot_preferences'),
                ),
                ListTile(
                  leading: const Icon(Icons.tablet_mac),
                  title: Text('kioskManagement'.tr()),
                  subtitle: const Text('Manage waiting room kiosk links'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.push('/settings/kiosk_management'),
                ),
                ListTile(
                  leading: const Icon(Icons.local_hospital_outlined),
                  title: const Text('Body Chart Marker Types'),
                  subtitle:
                      const Text('Customize clinical marker types and icons'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.push('/settings/marker_types'),
                ),
              ],
              _buildSectionHeader('appSettings'),
              ListTile(
                leading: const Icon(Icons.tv),
                title: const Text('Patient Calling Screen'),
                subtitle: const Text(
                    'Open the waiting room display window (HDMI/Cast)'),
                onTap: _openPresentationWindow,
              ),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: Text('notifications'.tr()),
                onTap: () => context.push('/settings/notifications'),
              ),
              ListTile(
                leading: const Icon(Icons.date_range_outlined),
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
                leading: const Icon(Icons.card_membership_outlined),
                title: Text('subscriptionAndBilling'.tr()),
                onTap: () => context.push('/settings/subscription'),
              ),
              if (OwnerNotifier().hasPermission(AppPermission.editSettings))
                ListTile(
                  leading: const Icon(Icons.payment_outlined),
                  title: const Text('Payment Gateway'),
                  subtitle: const Text('Configure booking payments'),
                  onTap: () => context.push('/settings/payment_gateway'),
                ),
              ListTile(
                leading: const Icon(Icons.security_outlined),
                title: Text('security'.tr()),
                onTap: () => context.push('/settings/security'),
              ),
              ListTile(
                leading: const Icon(Icons.model_training_outlined),
                title: Text('aiModel'.tr()),
                onTap: () => context.push('/settings/model_selection'),
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: Text('privacy'.tr()),
                onTap: () => context.push('/privacy'),
              ),
              _buildSectionHeader('support'),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: Text('helpSupport'.tr()),
                onTap: () => context.push('/help_support'),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
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
