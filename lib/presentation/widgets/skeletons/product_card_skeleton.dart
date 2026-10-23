import 'package:flutter/material.dart';
import 'shimmer_box.dart';

class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          const ShimmerBox(
            height: 100,
            borderRadius: 12,
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerBox(height: 12, width: 100),
                const SizedBox(height: 6),
                const ShimmerBox(height: 10, width: 70),
                const SizedBox(height: 10),
                Row(
                  children: const [
                    ShimmerBox(height: 14, width: 50),
                    SizedBox(width: 6),
                    ShimmerBox(height: 10, width: 40),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
