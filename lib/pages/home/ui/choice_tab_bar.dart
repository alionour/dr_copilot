import 'package:flutter/material.dart';

class ChipTabBar extends StatefulWidget {
  const ChipTabBar({super.key});

  @override
  State<ChipTabBar> createState() => _ChipTabBarState();
}

class _ChipTabBarState extends State<ChipTabBar> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      children: [
        ChoiceChip(
          label: const Text('PERSONAL'),
          selected: selectedIndex == 0,
          onSelected: (bool selected) {
            setState(() {
              selectedIndex = 0;
            });
          },
          selectedColor: Colors.white,
          labelStyle: TextStyle(
            color: selectedIndex == 0 ? const Color(0xFF1E1E2D) : Colors.white,
            fontWeight: FontWeight.w500,
          ),
          backgroundColor: const Color(0xFF1E1E2D),
        ),
        ChoiceChip(
          label: const Text('BUSINESS'),
          selected: selectedIndex == 1,
          onSelected: (bool selected) {
            setState(() {
              selectedIndex = 1;
            });
          },
          selectedColor: Colors.white,
          labelStyle: TextStyle(
            color: selectedIndex == 1 ? const Color(0xFF1E1E2D) : Colors.white,
            fontWeight: FontWeight.w500,
          ),
          backgroundColor: const Color(0xFF1E1E2D),
        ),
      ],
    );
  }
}
