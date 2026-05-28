import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoadingWidget extends StatelessWidget {
  final Widget child;

  const ShimmerLoadingWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[600]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: child,
    );
  }
}

class ShimmerBlock extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBlock({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white, // Color doesn't matter for Shimmer, just needs to be opaque
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class ShimmerList extends StatelessWidget {
  final int itemCount;

  const ShimmerList({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoadingWidget(
      child: ListView.builder(
        itemCount: itemCount,
        padding: const EdgeInsets.all(16.0),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ShimmerBlock(width: 48.0, height: 48.0, borderRadius: 24.0),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBlock(width: double.infinity, height: 16.0),
                    SizedBox(height: 8.0),
                    ShimmerBlock(width: 150.0, height: 16.0),
                    SizedBox(height: 8.0),
                    ShimmerBlock(width: 100.0, height: 16.0),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShimmerDetailsPage extends StatelessWidget {
  const ShimmerDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoadingWidget(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerBlock(width: double.infinity, height: 200.0, borderRadius: 12.0),
            const SizedBox(height: 24.0),
            const ShimmerBlock(width: 250.0, height: 32.0),
            const SizedBox(height: 16.0),
            const ShimmerBlock(width: double.infinity, height: 16.0),
            const SizedBox(height: 8.0),
            const ShimmerBlock(width: double.infinity, height: 16.0),
            const SizedBox(height: 8.0),
            const ShimmerBlock(width: 200.0, height: 16.0),
            const SizedBox(height: 32.0),
            Row(
              children: const [
                ShimmerBlock(width: 80.0, height: 80.0, borderRadius: 40.0),
                SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBlock(width: double.infinity, height: 16.0),
                      SizedBox(height: 8.0),
                      ShimmerBlock(width: 150.0, height: 16.0),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
