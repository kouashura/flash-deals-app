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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ShimmerBox(
            height: 100,
            borderRadius: 12,
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(height: 12, width: 100),
                SizedBox(height: 6),
                ShimmerBox(height: 10, width: 70),
                SizedBox(height: 10),
                Row(
                  children: [
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
