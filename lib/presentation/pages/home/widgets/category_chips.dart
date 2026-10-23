import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class CategoryChips extends StatefulWidget {
  final ValueChanged<String>? onSelected;

  const CategoryChips({super.key, this.onSelected});

  @override
  State<CategoryChips> createState() => _CategoryChipsState();
}

class _CategoryChipsState extends State<CategoryChips> {
  int _selected = 0;

  final _categories = const [
    {'id': 'all', 'icon': '🛒', 'label': 'Tout'},
    {'id': '1', 'icon': '🥛', 'label': 'Laitier'},
    {'id': '2', 'icon': '🥩', 'label': 'Viande'},
    {'id': '3', 'icon': '🍞', 'label': 'Boulangerie'},
    {'id': '4', 'icon': '🥤', 'label': 'Boissons'},
    {'id': '5', 'icon': '🧴', 'label': 'Hygiène'},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final cat = _categories[i];
          final selected = i == _selected;
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                setState(() => _selected = i);
                widget.onSelected?.call(cat['id']!);
              },
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        cat['icon']!,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat['label']!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                      color: selected
                          ? AppColors.primary
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
