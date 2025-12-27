import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/widgets/app_scaffold.dart';
import 'package:kattrick/widgets/map/unified_map_widget.dart';
import 'package:kattrick/widgets/map/map_mode.dart';

/// Map screen - shows hubs, games, and venues on an interactive map
///
/// Refactored to use UnifiedMapWidget with mode switching.
/// This screen is now just a thin wrapper that provides:
/// - App scaffold
/// - Mode filter chips
/// - Navigation handling
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapMode _selectedMode = MapMode.findVenues;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'מפה',
      showBottomNav: true,
      body: Stack(
        children: [
          // Main map widget
          UnifiedMapWidget(
            mode: _selectedMode,
            key: ValueKey(_selectedMode), // Force rebuild when mode changes
          ),

          // Filter chips overlay
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildModeChip(
                        mode: MapMode.findVenues,
                        label: 'מגרשים',
                        icon: Icons.stadium,
                      ),
                      const SizedBox(width: 8),
                      _buildModeChip(
                        mode: MapMode.exploreHubs,
                        label: 'הובים',
                        icon: Icons.groups,
                      ),
                      const SizedBox(width: 8),
                      _buildModeChip(
                        mode: MapMode.exploreGames,
                        label: 'משחקים',
                        icon: Icons.sports_soccer,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip({
    required MapMode mode,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedMode == mode;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? Colors.white : mode.primaryColor,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      selectedColor: mode.primaryColor,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedMode = mode;
          });
        }
      },
    );
  }
}
