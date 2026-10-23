#!/bin/bash
echo "🏠 Création de la Home..."

# ============================================================
# WIDGET: DELIVERY BANNER (1500 FCFA)
# ============================================================
cat > lib/presentation/pages/home/widgets/delivery_banner.dart << 'DART'
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/delivery_constants.dart';

class DeliveryBanner extends StatelessWidget {
  const DeliveryBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.delivery_dining, color: AppColors.success, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Livraison Abidjan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
                Text(
                  '${DeliveryConstants.abidjanDeliveryFee} FCFA • partout dans Abidjan',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
DART

# ============================================================
# WIDGET: COUNTDOWN TIMER
# ============================================================
cat > lib/presentation/pages/home/widgets/countdown_timer.dart << 'DART'
import 'dart:async';
import 'package:flutter/material.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime endTime;
  final Color color;

  const CountdownTimer({
    super.key,
    required this.endTime,
    this.color = Colors.white,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateRemaining();
    });
  }

  void _updateRemaining() {
    final diff = widget.endTime.difference(DateTime.now());
    setState(() {
      _remaining = diff.isNegative ? Duration.zero : diff;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _box(_two(_remaining.inHours)),
        const Text(' : '),
        _box(_two(_remaining.inMinutes % 60)),
        const Text(' : '),
        _box(_two(_remaining.inSeconds % 60)),
      ],
    );
  }

  Widget _box(String v) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          v,
          style: TextStyle(
            color: widget.color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );
}
DART

# ============================================================
# WIDGET: FLASH DEALS BANNER
# ============================================================
cat > lib/presentation/pages/home/widgets/flash_deals_banner.dart << 'DART'
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'countdown_timer.dart';

class FlashDealsBanner extends StatelessWidget {
  const FlashDealsBanner({super.key});

  @override
  Widget build(BuildContext context) {
    // Fin des deals : dans 5 heures
    final endTime = DateTime.now().add(const Duration(hours: 5));

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFFFF9800)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.flash_on, color: Colors.white, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'VENTE FLASH',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Se termine dans',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 6),
                CountdownTimer(endTime: endTime),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
DART

# ============================================================
# WIDGET: CATEGORY CHIPS
# ============================================================
cat > lib/presentation/pages/home/widgets/category_chips.dart << 'DART'
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class CategoryChips extends StatefulWidget {
  const CategoryChips({super.key});

  @override
  State<CategoryChips> createState() => _CategoryChipsState();
}

class _CategoryChipsState extends State<CategoryChips> {
  int _selected = 0;

  final _categories = const [
    {'icon': '🥛', 'label': 'Laitier'},
    {'icon': '🥩', 'label': 'Viande'},
    {'icon': '🍞', 'label': 'Boulangerie'},
    {'icon': '🥤', 'label': 'Boissons'},
    {'icon': '🧴', 'label': 'Hygiène'},
    {'icon': '🥫', 'label': 'Épicerie'},
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
          return GestureDetector(
            onTap: () => setState(() => _selected = i),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary
                        : Colors.white,
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
          );
        },
      ),
    );
  }
}
DART

# ============================================================
# WIDGET: PRODUCT CARD
# ============================================================
cat > lib/presentation/pages/home/widgets/product_card.dart << 'DART'
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/entities/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE + BADGES
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.image,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
                ),
                // BADGE RÉDUCTION
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '-${product.discountPercent.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                // BADGE EXPIRATION
                if (product.expiryBadge != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.expiryBadge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // CONTENU
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.storeName,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        Formatters.price(product.promoPrice),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          Formatters.price(product.normalPrice),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (product.isLowStock)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Plus que ${product.stock} en stock !',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
DART

echo "✅ Widgets de la Home créés !"
