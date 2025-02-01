import 'package:dr_copilot/src/features/copilot/presentation/pages/copilot_page.dart';
import 'package:dr_copilot/src/features/navigation_side/presentation/widgets/navigation_side.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const NavigationSide(
      child: CopilotPage(title: 'Dr Copilot'),
    );
  }
}
