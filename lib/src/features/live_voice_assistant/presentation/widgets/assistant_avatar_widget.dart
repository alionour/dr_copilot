import 'package:flutter/material.dart';
import 'package:avatar_glow/avatar_glow.dart';

/// Widget that displays the AI assistant avatar with animations
class AssistantAvatarWidget extends StatelessWidget {
  final bool isActive;
  final double size;
  final Color? color;

  const AssistantAvatarWidget({
    super.key,
    required this.isActive,
    this.size = 80,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final avatarColor = color ?? Theme.of(context).colorScheme.primary;
    
    return AvatarGlow(
      animate: isActive,
      glowColor: avatarColor,
      duration: const Duration(milliseconds: 2000),
      repeat: true,
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: avatarColor,
        child: Icon(
          Icons.psychology,
          size: size * 0.6,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }
}
