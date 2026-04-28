import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class Skeleton extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const Skeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class FoodCardSkeleton extends StatelessWidget {
  const FoodCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Skeleton(
              width: double.infinity,
              borderRadius: 24,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Skeleton(width: 60, height: 24, borderRadius: 12),
                    SizedBox(width: 8),
                    Skeleton(width: 60, height: 24, borderRadius: 12),
                  ],
                ),
                const SizedBox(height: 16),
                const Skeleton(width: 150, height: 20),
                const SizedBox(height: 8),
                const Skeleton(width: 100, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FoodDetailSkeleton extends StatelessWidget {
  const FoodDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Skeleton(width: double.infinity, height: 300, borderRadius: 0),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Skeleton(width: 200, height: 30),
              const SizedBox(height: 8),
              const Skeleton(width: 100, height: 16),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Skeleton(width: 80, height: 40, borderRadius: 20),
                  Skeleton(width: 80, height: 40, borderRadius: 20),
                  Skeleton(width: 80, height: 40, borderRadius: 20),
                ],
              ),
              const SizedBox(height: 32),
              const Skeleton(width: 150, height: 24),
              const SizedBox(height: 16),
              const Skeleton(width: double.infinity, height: 100),
            ],
          ),
        ),
      ],
    );
  }
}

class IngredientDetailSkeleton extends StatelessWidget {
  const IngredientDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Skeleton(width: double.infinity, height: 300, borderRadius: 0),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Skeleton(width: 180, height: 28),
              const SizedBox(height: 8),
              const Skeleton(width: 100, height: 16),
              const SizedBox(height: 32),
              const Skeleton(width: 150, height: 20),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Skeleton(width: 60, height: 80, borderRadius: 30),
                  Skeleton(width: 60, height: 80, borderRadius: 30),
                  Skeleton(width: 60, height: 80, borderRadius: 30),
                  Skeleton(width: 60, height: 80, borderRadius: 30),
                ],
              ),
              const SizedBox(height: 32),
              const Skeleton(width: double.infinity, height: 150),
            ],
          ),
        ),
      ],
    );
  }
}
