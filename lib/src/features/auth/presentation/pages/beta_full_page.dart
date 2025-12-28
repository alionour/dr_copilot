import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class BetaFullPage extends StatelessWidget {
  const BetaFullPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Custom Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_top_rounded,
                size: 64,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Beta Access Full',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Thank you for your interest in Dr. Copilot. Due to high demand, we have temporarily paused new signups to ensure the best experience for our current users.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.black54,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 32),
            Text(
              'Please check back later or contact support to join the waitlist.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black45,
                  ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () {
                final Uri emailLaunchUri = Uri(
                  scheme: 'mailto',
                  path: 'nourrehabcenter@gmail.com',
                  query: 'subject=Dr. Copilot Waitlist Request',
                );
                launchUrl(emailLaunchUri);
              },
              icon: const Icon(Icons.mail_outline),
              label: const Text('Join Waitlist via Email'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
