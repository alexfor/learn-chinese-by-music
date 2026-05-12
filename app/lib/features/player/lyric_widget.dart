import 'package:flutter/material.dart';
import '../../models/lyric.dart';

class LyricWidget extends StatefulWidget {
  final LyricJson lyricJson;
  final int currentLineIndex;
  final String displayLang;
  final void Function(int lineIndex)? onLineTap;

  const LyricWidget({
    super.key,
    required this.lyricJson,
    required this.currentLineIndex,
    this.displayLang = 'en',
    this.onLineTap,
  });

  @override
  State<LyricWidget> createState() => _LyricWidgetState();
}

class _LyricWidgetState extends State<LyricWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(LyricWidget old) {
    super.didUpdateWidget(old);
    if (old.currentLineIndex != widget.currentLineIndex &&
        widget.currentLineIndex >= 0) {
      _scrollToLine(widget.currentLineIndex);
    }
  }

  void _scrollToLine(int index) {
    if (!_scrollController.hasClients) return;

    const lineEstimateHeight = 80.0;
    const visibleHeight = 400.0;
    final targetOffset = (index * lineEstimateHeight) - (visibleHeight / 2);

    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 200, horizontal: 24),
      itemCount: widget.lyricJson.lines.length,
      itemBuilder: (context, index) {
        final line = widget.lyricJson.lines[index];
        final isHighlighted = index == widget.currentLineIndex;

        return GestureDetector(
          onTap: () => widget.onLineTap?.call(index),
          behavior: HitTestBehavior.translucent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: _buildLine(line, isHighlighted),
          ),
        );
      },
    );
  }

  Widget _buildLine(LyricLine line, bool isHighlighted) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor =
        isHighlighted ? colorScheme.primary : colorScheme.onSurface;

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
          if (line.translations.containsKey(widget.displayLang)) ...[
            const SizedBox(height: 2),
            Text(
              line.translations[widget.displayLang]!,
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
