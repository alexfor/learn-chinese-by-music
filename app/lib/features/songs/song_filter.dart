import 'package:flutter/material.dart';

const _styles = ['all', 'pop', 'folk', 'gufeng', 'children'];

const _styleLabels = {
  'all': 'All',
  'pop': 'Pop',
  'folk': 'Folk',
  'gufeng': 'Gufeng',
  'children': 'Kids',
};

class SongFilterBar extends StatelessWidget {
  final String? selectedStyle;
  final ValueChanged<String?> onStyleChanged;

  const SongFilterBar({
    super.key,
    this.selectedStyle,
    required this.onStyleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: _styles.map((style) {
          final isSelected = (style == 'all')
              ? selectedStyle == null
              : selectedStyle == style;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_styleLabels[style]!),
              selected: isSelected,
              onSelected: (_) {
                onStyleChanged(style == 'all' ? null : style);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
