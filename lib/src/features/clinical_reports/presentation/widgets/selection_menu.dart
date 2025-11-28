import 'package:flutter/material.dart';

class SelectionMenu extends StatelessWidget {
  final Function(String) onApply;
  final VoidCallback onClose;

  const SelectionMenu({
    super.key,
    required this.onApply,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Text(
                    'AI Actions',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const Divider(height: 8),
            _MenuOption(
              icon: Icons.spellcheck,
              label: 'Fix Grammar',
              onTap: () => onApply('Fix grammar and spelling'),
            ),
            _MenuOption(
              icon: Icons.compress,
              label: 'Shorten',
              onTap: () => onApply('Make it shorter and more concise'),
            ),
            _MenuOption(
              icon: Icons.expand,
              label: 'Expand',
              onTap: () => onApply('Expand with more detail'),
            ),
            _MenuOption(
              icon: Icons.business,
              label: 'Professional',
              onTap: () => onApply('Rewrite in a professional clinical tone'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
