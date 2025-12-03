import 'package:dr_copilot/src/features/copilot_chat/presentation/pages/copilot_page.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CopilotPage(title: 'appTitle'.tr());
  }
}
