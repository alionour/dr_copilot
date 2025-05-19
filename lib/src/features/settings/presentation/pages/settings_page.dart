import 'package:dr_copilot/src/core/app/notifiers/theme_notifier.dart';
import 'package:dr_copilot/src/features/navigation_side/presentation/widgets/nav_menu_button.dart';
import 'package:dr_copilot/src/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FocusNode _focusNode = FocusNode();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<SettingsBloc>().add(LoadSettingsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final navMenuButton = NavMenuButtonProvider.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr()),
        leading: Icon(Icons.settings),
        actions: [navMenuButton ?? SizedBox()],
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0.5,
      ),
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (FocusNode node, KeyEvent event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              setState(() {
                _selectedIndex =
                    (_selectedIndex + 1) % 8; // 8 items in the list
              });
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              setState(() {
                _selectedIndex =
                    (_selectedIndex - 1 + 8) % 8; // 8 items in the list
              });
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                children: <Widget>[
                  BlocBuilder<SettingsBloc, SettingsState>(
                    builder: (context, state) {
                      return ListTile(
                        leading: const Icon(Icons.color_lens),
                        title: Text(
                          state is SettingsDarkMode
                              ? 'lightMode'.tr()
                              : 'darkMode'.tr(),
                        ),
                        selected: _selectedIndex == 0,
                        onTap: () {
                          setState(() {
                            _selectedIndex = 0;
                          });
                          context.read<SettingsBloc>().add(ToggleThemeEvent());
                          context.read<ThemeNotifier>().toggleTheme();
                        },
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock),
                    title: Text('privacy'.tr()),
                    selected: _selectedIndex == 1,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 1;
                      });
                      context.go('/privacy');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: Text('notifications'.tr()),
                    selected: _selectedIndex == 2,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 2;
                      });
                      // Handle notifications settings tap
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text('language'.tr()),
                    selected: _selectedIndex == 3,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 3;
                      });
                    },
                    trailing: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: context.locale
                            .languageCode, // Use EasyLocalization's locale
                        onChanged: (String? newLocale) {
                          if (newLocale != null) {
                            context
                                .read<SettingsBloc>()
                                .add(ChangeLocaleEvent(newLocale));
                            context.setLocale(Locale(newLocale));
                          }
                        },
                        items: const [
                          DropdownMenuItem(
                            value: 'en',
                            child: Row(
                              children: [
                                Icon(Icons.language, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('English'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'ar',
                            child: Row(
                              children: [
                                Icon(Icons.language, color: Colors.green),
                                SizedBox(width: 8),
                                Text('Arabic'),
                              ],
                            ),
                          ),
                        ],
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Colors.black),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.security),
                    title: Text('security'.tr()),
                    selected: _selectedIndex == 4,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 4;
                      });
                      // Handle security settings tap
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.help),
                    title: Text('helpSupport'.tr()),
                    selected: _selectedIndex == 5,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 5;
                      });
                      context.go('/help_support');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: Text('about'.tr()),
                    selected: _selectedIndex == 6,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 6;
                      });
                      context.go('/about');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
