import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:kattrick/models/player.dart';
import 'package:kattrick/models/player_stats.dart';

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
    return Card(
      elevation: isSelected ? 8 : 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected 
          ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
          : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isSelected 
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
              : null,
          ),
          child: showRadarChart && latestStats != null
              ? _buildEnhancedPlayerCard(context)
              : _buildCompactPlayerCard(context),
        ),
      ),
    );
  }

  Widget _buildPlayerAvatar() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            _getAvatarColor(player.name).withValues(alpha: 0.7),
            _getAvatarColor(player.name),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          player.name.split(' ').map((e) => e[0]).take(2).join().toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactPlayerCard(BuildContext context) {
    return Row(
      children: [
        if (showRank && rank != null) ...[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getRankColor(rank!, context),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        _buildPlayerAvatar(),
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
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (player.isInForm) ...[
                    Icon(Icons.trending_up, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                  ],
                  if (player.isImproving) ...[
                    Icon(Icons.arrow_upward, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                  ],
                  _buildGradeBadge(),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                player.attributes.preferredPosition,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.star,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    player.currentRankScore.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${player.gamesPlayed} games',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _buildPlayerStats(),
      ],
    );
  }

  Widget _buildEnhancedPlayerCard(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            if (showRank && rank != null) ...[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getRankColor(rank!, context),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
            _buildPlayerAvatar(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          player.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildGradeBadge(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        player.attributes.preferredPosition,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (player.isInForm) ...[
                        Icon(Icons.trending_up, size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Text('Hot Form', style: TextStyle(color: Colors.green, fontSize: 12)),
                      ],
                      if (player.isImproving) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_upward, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text('Improving', style: TextStyle(color: Colors.blue, fontSize: 12)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        player.currentRankScore.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.sports_soccer,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${player.gamesPlayed} games',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildRadarChart(context),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAttributesList(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGradeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getGradeColor(player.overallGrade),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        player.overallGrade,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildRadarChart(BuildContext context) {
    if (latestStats == null) return const SizedBox();
    
    return SizedBox(
      height: 120,
      child: RadarChart(
        RadarChartData(
          radarTouchData: RadarTouchData(enabled: false),
          dataSets: [
            RadarDataSet(
              fillColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              borderColor: Theme.of(context).colorScheme.primary,
              borderWidth: 2,
              entryRadius: 3,
              dataEntries: latestStats!.attributesList
                  .map((value) => RadarEntry(value: value))
                  .toList(),
            ),
          ],
          radarBorderData: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
          titleTextStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: 8,
          ),
          getTitle: (index, angle) {
            final titles = ['DEF', 'PAS', 'SHO', 'DRI', 'PHY', 'LEA', 'TEA', 'CON'];
            return RadarChartTitle(
              text: titles[index % titles.length],
              angle: angle,
            );
          },
          tickCount: 5,
          tickBorderData: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
          gridBorderData: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
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
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    names[i],
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                Container(
                  width: 30,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getAttributeColor(attributes[i]).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: attributes[i] / 10.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getAttributeColor(attributes[i]),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 20,
                  child: Text(
                    attributes[i].toStringAsFixed(1),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _getAttributeColor(attributes[i]),
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

  Widget _buildPlayerStats() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatChip('SPD', player.attributes.speed),
        const SizedBox(height: 4),
        _buildStatChip('STR', player.attributes.strength),
      ],
    );
  }

  Widget _buildStatChip(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getStatColor(value).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _getStatColor(value),
            ),
          ),
        ],
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[name.hashCode % colors.length];
  }

  Color _getRankColor(int rank, BuildContext context) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.brown[400]!;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Color _getStatColor(int value) {
    if (value >= 8) return Colors.green;
    if (value >= 6) return Colors.orange;
    return Colors.red;
  }
  
  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'S': return Colors.purple;
      case 'A+': case 'A': case 'A-': return Colors.green;
      case 'B+': case 'B': case 'B-': return Colors.blue;
      case 'C+': case 'C': case 'C-': return Colors.orange;
      case 'D': return Colors.red;
      case 'F': return Colors.grey;
      default: return Colors.grey;
    }
  }
  
  Color _getAttributeColor(double value) {
    if (value >= 8.5) return Colors.green;
    if (value >= 7.0) return Colors.lightGreen;
    if (value >= 5.5) return Colors.orange;
    if (value >= 4.0) return Colors.redAccent;
    return Colors.red;
  }
}