import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/data/proteams_repository.dart';
import 'package:kattrick/theme/premium_theme.dart';

/// Widget for selecting a professional team (favorite team)
class ProTeamSelector extends ConsumerStatefulWidget {
  final String? selectedTeamId;
  final Function(String?) onTeamSelected;
  final String label;
  final bool showNoneOption;

  const ProTeamSelector({
    super.key,
    this.selectedTeamId,
    required this.onTeamSelected,
    this.label = 'קבוצה אהודה',
    this.showNoneOption = true,
  });

  @override
  ConsumerState<ProTeamSelector> createState() => _ProTeamSelectorState();
}

class _ProTeamSelectorState extends ConsumerState<ProTeamSelector> {
  String _searchQuery = '';
  String _selectedLeague = 'all'; // 'all', 'premier', 'national'

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: PremiumTypography.labelMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showTeamSelectionDialog(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: PremiumColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                if (widget.selectedTeamId != null) ...[
                  // Show selected team logo and name
                  FutureBuilder<ProTeam?>(
                    future: ref
                        .read(proTeamsRepositoryProvider)
                        .getTeam(widget.selectedTeamId!),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        final team = snapshot.data!;
                        return Row(
                          children: [
                            _buildTeamLogo(team.logoUrl, size: 32),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  team.name,
                                  style: PremiumTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  team.league == 'premier'
                                      ? 'ליגת העל'
                                      : 'ליגה לאומית',
                                  style: PremiumTypography.bodySmall.copyWith(
                                    color: PremiumColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }
                      return const Text('טוען...');
                    },
                  ),
                ] else ...[
                  const Icon(Icons.sports_soccer,
                      color: PremiumColors.textSecondary),
                  const SizedBox(width: 12),
                  Text(
                    'בחר קבוצה אהודה',
                    style: PremiumTypography.bodyMedium.copyWith(
                      color: PremiumColors.textSecondary,
                    ),
                  ),
                ],
                const Spacer(),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showTeamSelectionDialog(BuildContext context) async {
    final teamsAsync = await ref.read(allProTeamsProvider.future);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'בחר קבוצה אהודה',
                          style: PremiumTypography.heading3,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Search field
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'חפש קבוצה...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    // League filter
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildLeagueChip('all', 'הכל'),
                          const SizedBox(width: 8),
                          _buildLeagueChip('premier', 'ליגת העל'),
                          const SizedBox(width: 8),
                          _buildLeagueChip('national', 'ליגה לאומית'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Teams list
              Expanded(
                child: StatefulBuilder(
                  builder: (context, setState) {
                    var filteredTeams = teamsAsync;

                    // Filter by league
                    if (_selectedLeague != 'all') {
                      filteredTeams = filteredTeams
                          .where((t) => t.league == _selectedLeague)
                          .toList();
                    }

                    // Filter by search
                    if (_searchQuery.isNotEmpty) {
                      filteredTeams = filteredTeams
                          .where((t) =>
                              t.name
                                  .toLowerCase()
                                  .contains(_searchQuery.toLowerCase()) ||
                              t.nameEn
                                  .toLowerCase()
                                  .contains(_searchQuery.toLowerCase()))
                          .toList();
                    }

                    return ListView(
                      children: [
                        // None option
                        if (widget.showNoneOption)
                          _buildTeamTile(
                            context,
                            null,
                            'אין קבוצה אהודה',
                            '',
                            null,
                          ),
                        // Teams
                        ...filteredTeams.map((team) => _buildTeamTile(
                              context,
                              team.teamId,
                              team.name,
                              team.league == 'premier'
                                  ? 'ליגת העל'
                                  : 'ליגה לאומית',
                              team.logoUrl,
                            )),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeagueChip(String value, String label) {
    final isSelected = _selectedLeague == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedLeague = value;
        });
      },
      backgroundColor: Colors.transparent,
      selectedColor: PremiumColors.primary.withOpacity(0.2),
      checkmarkColor: PremiumColors.primary,
    );
  }

  Widget _buildTeamTile(
    BuildContext context,
    String? teamId,
    String name,
    String league,
    String? logoUrl,
  ) {
    final isSelected = widget.selectedTeamId == teamId;

    return ListTile(
      leading: logoUrl != null
          ? _buildTeamLogo(logoUrl)
          : const Icon(Icons.sports_soccer, color: PremiumColors.textSecondary),
      title: Text(
        name,
        style: PremiumTypography.bodyMedium.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: league.isNotEmpty ? Text(league) : null,
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: PremiumColors.primary)
          : null,
      onTap: () {
        widget.onTeamSelected(teamId);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildTeamLogo(String logoUrl, {double size = 40}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: logoUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholder: (context, url) => Container(
          width: size,
          height: size,
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: size,
          height: size,
          color: Colors.grey[200],
          child: const Icon(Icons.sports_soccer, size: 20),
        ),
      ),
    );
  }
}
