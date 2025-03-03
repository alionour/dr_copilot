import 'package:dr_copilot/main.dart';
import 'package:dr_copilot/src/features/settings/presentation/bloc/settings_bloc.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
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
                              ? 'Light Mode'
                              : 'Dark Mode',
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
                    title: const Text('Privacy'),
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
                    title: const Text('Notifications'),
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
                    title: const Text('Language'),
                    selected: _selectedIndex == 3,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 3;
                      });
                      // Handle language settings tap
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.security),
                    title: const Text('Security'),
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
                    title: const Text('Help & Support'),
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
                    title: const Text('About'),
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
