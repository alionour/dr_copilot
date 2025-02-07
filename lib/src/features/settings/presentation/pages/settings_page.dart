import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
                _selectedIndex = (_selectedIndex + 1) % 5; // 5 items in the list
              });
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              setState(() {
                _selectedIndex = (_selectedIndex - 1 + 5) % 5; // 5 items in the list
              });
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Column(
          children: <Widget>[
            const Center(
              child: Text('Navigation is '),
            ),
            Expanded(
              child: ListView(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.account_circle),
                    title: const Text('Account'),
                    selected: _selectedIndex == 0,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 0;
                      });
                      // Handle account settings tap
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('Notifications'),
                    selected: _selectedIndex == 1,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 1;
                      });
                      // Handle notifications settings tap
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock),
                    title: const Text('Privacy'),
                    selected: _selectedIndex == 2,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 2;
                      });
                      // Handle privacy settings tap
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.help),
                    title: const Text('Help & Support'),
                    selected: _selectedIndex == 3,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 3;
                      });
                      // Handle help & support tap
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('About'),
                    selected: _selectedIndex == 4,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 4;
                      });
                      // Handle about tap
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
