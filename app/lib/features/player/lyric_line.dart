import 'package:flutter/material.dart';
import '../../models/lyric.dart';

class LyricLineWidget extends StatelessWidget {
  final LyricLine line;
  final bool isHighlighted;
  final String displayLang;

  const LyricLineWidget({
    super.key,
    required this.line,
    this.isHighlighted = false,
    this.displayLang = 'en',
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = isHighlighted ? colorScheme.primary : colorScheme.onSurface;

    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 300),
      style: TextStyle(
        fontSize: isHighlighted ? 22 : 18,
        color: textColor,
        fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(line.zh),
          const SizedBox(height: 2),
          Text(
            line.pinyin,
            style: TextStyle(
              fontSize: isHighlighted ? 14 : 12,
              color: isHighlighted
                  ? colorScheme.primary.withAlpha(180)
                  : colorScheme.outline,
            ),
          ),
          if (line.translations.containsKey(displayLang)) ...[
            const SizedBox(height: 2),
            Text(
              line.translations[displayLang]!,
              style: TextStyle(
                fontSize: isHighlighted ? 13 : 11,
                color: isHighlighted
                    ? colorScheme.primary.withAlpha(160)
                    : colorScheme.outline.withAlpha(180),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
