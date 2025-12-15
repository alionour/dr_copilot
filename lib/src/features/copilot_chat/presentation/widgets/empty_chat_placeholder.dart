import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class EmptyChatPlaceholder extends StatelessWidget {
  const EmptyChatPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth * 0.9;
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth < 600 ? maxWidth : 600,
            ),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: LayoutBuilder(
                builder: (context, textConstraints) {
                  return Text(
                    'noMessages'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      foreground: Paint()
                        ..shader =
                            LinearGradient(
                              colors: const <Color>[
                                Color(0xFF6A11CB),
                                Color(0xFF2575FC),
                              ],
                            ).createShader(
                              Rect.fromLTWH(
                                0.0,
                                0.0,
                                textConstraints.maxWidth,
                                100.0,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

