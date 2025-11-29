import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final String? title;
  final VoidCallback? onActionPressed;
  final String? actionLabel;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.title,
    this.onActionPressed,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/svg/empty_state.svg',
              height: 200,
              width: 200,
            ),
            const SizedBox(height: 24),
            if (title != null) ...[
              Text(
                title!,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onActionPressed != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onActionPressed,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
