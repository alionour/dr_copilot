import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('helpSupport'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/home');
          },
        ),
      ),
      body:  Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'helpSupport'.tr(),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'helpSupportContent'.tr(),
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'userGuide'.tr(),
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'faq'.tr(),
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'contactSupport'.tr(),
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'positiveExperience'.tr(),
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
