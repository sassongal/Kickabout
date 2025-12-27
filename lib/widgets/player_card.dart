import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:kattrick/features/profile/domain/models/player.dart';
import 'package:kattrick/features/profile/domain/models/player_stats.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:kattrick/widgets/common/premium_card.dart';
import 'package:kattrick/widgets/optimized_image.dart';

class PlayerCard extends StatelessWidget {
  final Player player;
  final bool showRank;
  final int? rank;
  final VoidCallback? onTap;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final bool showRadarChart;
  final PlayerStats? latestStats;

  const PlayerCard({
    super.key,
    required this.player,
    this.showRank = false,
    this.rank,
    this.onTap,
    this.isSelected = false,
    this.onLongPress,
    this.showRadarChart = false,
    this.latestStats,
  });

  @override
  Widget build(BuildContext context) {
    // If showRadarChart is true, we display the full "Profile Card" layout.
    // Otherwise, we display the compact row layout for lists.
    final bool isEnhanced = showRadarChart && latestStats != null;

    return PremiumCard(
      onTap: onTap,
      borderColor: isSelected ? PremiumColors.primary : null,
      showGlow: isSelected,
      padding: EdgeInsets.zero, // We handle padding internally for full control
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: isEnhanced
          ? _buildProfileCard(context)
          : _buildCompactListCard(context),
    );
  }

  // --- COMPACT LIST CARD ---
  Widget _buildCompactListCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _buildRankBadge(context),
          const SizedBox(width: 12),
          _buildAvatar(size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        player.name,
                        style: PremiumTypography.heading3
                            .copyWith(fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (player.isInForm)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(Icons.local_fire_department,
                            size: 16, color: PremiumColors.accent),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      player.attributes.preferredPosition,
                      style: PremiumTypography.bodySmall.copyWith(
                        color: PremiumColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildConsistencyBadge(),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRatingBadge(context),
              const SizedBox(height: 4),
              Text(
                '${player.gamesPlayed} משחקים',
                style: PremiumTypography.labelSmall.copyWith(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- FULL PROFILE CARD (ReactBits Style) ---
  Widget _buildProfileCard(BuildContext context) {
    return Column(
      children: [
        // 1. Cover Image / Gradient Banner
        SizedBox(
          height: 80,
          width: double.infinity,
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
              ),
              // Abstract curve or pattern could go here
              Positioned(
                top: 8,
                right: 8,
                child: _buildRankBadge(context), // Rank floats on cover
              ),
            ],
          ),
        ),

        // 2. Avatar Area (Overlapping)
        Transform.translate(
          offset: const Offset(0, -32),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: PremiumColors.surface, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: _buildAvatar(size: 80),
              ),
              const SizedBox(height: 8),

              // 3. Name & Key Info
              Text(
                player.name,
                style: PremiumTypography.heading2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sports_soccer,
                      size: 14, color: PremiumColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    player.attributes.preferredPosition.toUpperCase(),
                    style: PremiumTypography.bodySmall.copyWith(
                      color: PremiumColors.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                      width: 1, height: 12, color: PremiumColors.divider),
                  const SizedBox(width: 12),
                  Text(
                    'דירוג ${player.currentRankScore.toStringAsFixed(1)}',
                    style: PremiumTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 4. Stats Grid
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              _buildStatsRow(context),
              const SizedBox(height: 16),
              if (latestStats != null) ...[
                SizedBox(
                  height: 140,
                  child: _buildRadarChart(context),
                ),
                const SizedBox(height: 16),
                _buildAttributesList(context),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildAvatar({required double size}) {
    if (player.photoUrl != null && player.photoUrl!.isNotEmpty) {
      return ClipOval(
        child: OptimizedImage(
          imageUrl: player.photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: _buildInitialsAvatar(size),
        ),
      );
    }
    return _buildInitialsAvatar(size);
  }

  Widget _buildInitialsAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            _getAvatarColor(player.name),
            _getAvatarColor(player.name).withOpacity(0.7),
          ],
          begin: Alignment.bottomRight,
          end: Alignment.topLeft,
        ),
      ),
      child: Center(
        child: Text(
          player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }

  Widget _buildRankBadge(BuildContext context) {
    if (!showRank || rank == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _getRankColor(rank!, context),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Text(
        '#$rank',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildRatingBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getGradeColor(player.overallGrade).withOpacity(0.15),
        border:
            Border.all(color: _getGradeColor(player.overallGrade), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        player.currentRankScore.toStringAsFixed(1),
        style: TextStyle(
          color: _getGradeColor(player.overallGrade),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildConsistencyBadge() {
    // Example of "tasteful sub-sections/slots"
    if (!player.isInForm) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: PremiumColors.accent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'IN FORM',
        style: TextStyle(
            fontSize: 8,
            color: PremiumColors.accent,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    // Map available data to a clean row
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem('GAMES', '${player.gamesPlayed}'),
        // We don't have Age/Foot, keeping it clean with existing data.
        // Maybe add "Grade" here prominently?
        _buildStatItem('GRADE', player.overallGrade,
            color: _getGradeColor(player.overallGrade)),
        // Speed/Strength form attributes
        _buildStatItem('SPD', '${player.attributes.speed}'),
        _buildStatItem('STR', '${player.attributes.strength}'),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          label,
          style: PremiumTypography.labelSmall
              .copyWith(color: PremiumColors.textSecondary, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: PremiumTypography.heading3.copyWith(
              fontSize: 16, color: color ?? PremiumColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildRadarChart(BuildContext context) {
    return RadarChart(
      RadarChartData(
        radarTouchData: RadarTouchData(enabled: false),
        dataSets: [
          RadarDataSet(
            fillColor: PremiumColors.primary.withOpacity(0.2),
            borderColor: PremiumColors.primary,
            borderWidth: 2,
            entryRadius: 3,
            dataEntries: latestStats!.attributesList
                .map((value) => RadarEntry(value: value))
                .toList(),
          ),
        ],
        radarBorderData: BorderSide(
          color: PremiumColors.surfaceVariant,
        ),
        titleTextStyle: PremiumTypography.labelSmall.copyWith(fontSize: 9),
        getTitle: (index, angle) {
          final titles = PlayerStats.attributeNames
              .map((e) => e.substring(0, 3).toUpperCase())
              .toList();
          // Adjust usage based on list length
          final safeTitle = index < titles.length ? titles[index] : '';
          return RadarChartTitle(
            text: safeTitle,
            angle: angle,
          );
        },
        tickCount: 5,
        tickBorderData:
            const BorderSide(color: Colors.transparent), // Cleaner look
        gridBorderData: BorderSide(
          color: PremiumColors.divider.withOpacity(0.1),
        ),
      ),
    );
  }

  Widget _buildAttributesList(BuildContext context) {
    if (latestStats == null) return const SizedBox();

    final attributes = latestStats!.attributesList;
    final names = PlayerStats.attributeNames;

    return Column(
      children: [
        for (int i = 0; i < attributes.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text(
                    names[i],
                    style:
                        PremiumTypography.labelSmall.copyWith(fontSize: 10),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: _getAttributeColor(attributes[i]).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: attributes[i] / 10.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getAttributeColor(attributes[i]),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 24,
                  child: Text(
                    attributes[i].toStringAsFixed(1),
                    style: PremiumTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getAttributeColor(attributes[i]),
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // --- COLORS ---

  Color _getAvatarColor(String name) {
    if (name.isEmpty) return Colors.grey;
    final colors = [
      Colors.redAccent,
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.tealAccent,
      Colors.indigoAccent,
      Colors.pinkAccent,
    ];
    return colors[name.hashCode % colors.length];
  }

  Color _getRankColor(int rank, BuildContext context) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return PremiumColors.primary;
    }
  }

  Color _getGradeColor(String grade) {
    if (grade.startsWith('S') || grade.startsWith('A')) {
      return PremiumColors.success;
    }
    if (grade.startsWith('B')) return PremiumColors.primary;
    if (grade.startsWith('C')) return Colors.orange;
    return Colors.red;
  }

  Color _getAttributeColor(double value) {
    if (value >= 8.5) return PremiumColors.success;
    if (value >= 7.0) return Colors.lightGreen;
    if (value >= 5.5) return Colors.orange;
    if (value >= 4.0) return Colors.redAccent;
    return Colors.red;
  }
}
