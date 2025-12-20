import 'package:flutter/material.dart';
import 'package:kattrick/widgets/premium/skeleton_loader.dart';
import 'package:kattrick/theme/premium_theme.dart';

/// Skeleton that matches NextGameSpotlightCard layout exactly.
///
/// Use this while the next game data is loading to prevent layout shift
/// and provide visual feedback to the user.
class SkeletonNextGameCard extends StatelessWidget {
  const SkeletonNextGameCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: PremiumSpacing.md),
      padding: EdgeInsets.all(PremiumSpacing.lg),
      decoration: BoxDecoration(
        color: PremiumColors.surface,
        borderRadius: BorderRadius.circular(PremiumRadii.xl),
        border: Border.all(color: PremiumColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: "Next Game" badge + time indicator
          Row(
            children: const [
              SkeletonLoader(width: 100, height: 24, borderRadius: 12),
              Spacer(),
              SkeletonLoader(width: 80, height: 20, borderRadius: 10),
            ],
          ),
          const SizedBox(height: 20),

          // Date and time row
          Row(
            children: const [
              // Calendar icon placeholder
              SkeletonLoader(width: 20, height: 20, borderRadius: 4),
              SizedBox(width: 8),
              SkeletonLoader(width: 120, height: 18),
              Spacer(),
              // Clock icon placeholder
              SkeletonLoader(width: 20, height: 20, borderRadius: 4),
              SizedBox(width: 8),
              SkeletonLoader(width: 50, height: 18),
            ],
          ),
          const SizedBox(height: 16),

          // Hub name row
          Row(
            children: const [
              // Hub icon placeholder
              SkeletonLoader(width: 24, height: 24, borderRadius: 12),
              SizedBox(width: 12),
              SkeletonLoader(width: 160, height: 20),
            ],
          ),
          const SizedBox(height: 12),

          // Venue row
          Row(
            children: const [
              // Location icon placeholder
              SkeletonLoader(width: 20, height: 20, borderRadius: 4),
              SizedBox(width: 12),
              SkeletonLoader(width: 140, height: 16),
            ],
          ),
          const SizedBox(height: 24),

          // Player avatars row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return Padding(
                padding: EdgeInsets.only(left: index == 0 ? 0 : 0),
                child: Transform.translate(
                  offset: Offset(-index * 8.0, 0),
                  child: const SkeletonLoader(
                      width: 32, height: 32, borderRadius: 16),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // CTA button placeholder
          const SkeletonLoader(
            width: double.infinity,
            height: 48,
            borderRadius: 12,
          ),
        ],
      ),
    );
  }
}

/// Skeleton for a single hub card in the carousel
class SkeletonHubCarouselCard extends StatelessWidget {
  const SkeletonHubCarouselCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: EdgeInsets.only(right: PremiumSpacing.md),
      decoration: BoxDecoration(
        color: PremiumColors.surface,
        borderRadius: BorderRadius.circular(PremiumRadii.lg),
        border: Border.all(color: PremiumColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero image placeholder
          const SkeletonLoader(
            width: double.infinity,
            height: 120,
            borderRadius: 16,
          ),
          Padding(
            padding: EdgeInsets.all(PremiumSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hub name
                const SkeletonLoader(width: 140, height: 18),
                const SizedBox(height: 8),
                // Member count
                Row(
                  children: const [
                    SkeletonLoader(width: 16, height: 16, borderRadius: 8),
                    SizedBox(width: 6),
                    SkeletonLoader(width: 80, height: 14),
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

/// Skeleton for the full hubs carousel section
class SkeletonHubsCarousel extends StatelessWidget {
  const SkeletonHubsCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: PremiumSpacing.md),
          child: Row(
            children: const [
              SkeletonLoader(width: 100, height: 20),
              Spacer(),
              SkeletonLoader(width: 60, height: 16),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Horizontal scroll of hub cards
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: PremiumSpacing.md),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3, // Show 3 skeleton cards
            itemBuilder: (context, index) => const SkeletonHubCarouselCard(),
          ),
        ),
      ],
    );
  }
}

/// Skeleton for the profile summary card
class SkeletonProfileSummaryCard extends StatelessWidget {
  const SkeletonProfileSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: PremiumSpacing.md),
      padding: EdgeInsets.all(PremiumSpacing.lg),
      decoration: BoxDecoration(
        color: PremiumColors.surface,
        borderRadius: BorderRadius.circular(PremiumRadii.lg),
        border: Border.all(color: PremiumColors.border),
      ),
      child: Row(
        children: [
          // Avatar
          const SkeletonLoader(width: 56, height: 56, borderRadius: 28),
          const SizedBox(width: 16),

          // Name and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonLoader(width: 140, height: 20),
                SizedBox(height: 8),
                SkeletonLoader(width: 100, height: 14),
              ],
            ),
          ),

          // Toggle placeholder
          const SkeletonLoader(width: 50, height: 28, borderRadius: 14),
        ],
      ),
    );
  }
}

/// Skeleton for the weather vibe widget at the top
class SkeletonWeatherVibeWidget extends StatelessWidget {
  const SkeletonWeatherVibeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: PremiumSpacing.md),
      padding: EdgeInsets.all(PremiumSpacing.md),
      decoration: BoxDecoration(
        color: PremiumColors.surface,
        borderRadius: BorderRadius.circular(PremiumRadii.md),
        border: Border.all(color: PremiumColors.border),
      ),
      child: Row(
        children: [
          // Weather icon
          const SkeletonLoader(width: 48, height: 48, borderRadius: 24),
          const SizedBox(width: 16),

          // Weather info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonLoader(width: 100, height: 18),
                SizedBox(height: 6),
                SkeletonLoader(width: 160, height: 14),
              ],
            ),
          ),

          // Temperature
          const SkeletonLoader(width: 40, height: 32, borderRadius: 8),
        ],
      ),
    );
  }
}

/// Complete home screen skeleton combining all sections
class SkeletonHomeScreen extends StatelessWidget {
  const SkeletonHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          SizedBox(height: PremiumSpacing.md),
          const SkeletonWeatherVibeWidget(),
          SizedBox(height: PremiumSpacing.lg),
          const SkeletonNextGameCard(),
          SizedBox(height: PremiumSpacing.lg),
          const SkeletonProfileSummaryCard(),
          SizedBox(height: PremiumSpacing.lg),
          const SkeletonHubsCarousel(),
        ],
      ),
    );
  }
}
