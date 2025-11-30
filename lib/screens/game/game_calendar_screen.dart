import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kattrick/widgets/futuristic/futuristic_scaffold.dart';
import 'package:kattrick/widgets/futuristic/skeleton_loader.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/utils/snackbar_helper.dart';

/// Game Calendar Screen - לוח שנה למשחקים
class GameCalendarScreen extends ConsumerStatefulWidget {
  final String? hubId; // Optional: filter by hub

  const GameCalendarScreen({
    super.key,
    this.hubId,
  });

  @override
  ConsumerState<GameCalendarScreen> createState() => _GameCalendarScreenState();
}

class _GameCalendarScreenState extends ConsumerState<GameCalendarScreen> {
  DateTime _selectedMonth = DateTime.now();
  Map<DateTime, List<Game>> _gamesByDate = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    setState(() => _isLoading = true);
    
    try {
      final gamesRepo = ref.read(gamesRepositoryProvider);
      List<Game> games;

      if (widget.hubId != null) {
        games = await gamesRepo.getGamesByHub(widget.hubId!);
      } else {
        // Get all games for current user's hubs
        final currentUserId = ref.read(currentUserIdProvider);
        if (currentUserId == null) {
          games = [];
        } else {
          final hubsRepo = ref.read(hubsRepositoryProvider);
          final userHubs = await hubsRepo.getHubsByMember(currentUserId);
          final allGames = <Game>[];
          for (final hub in userHubs) {
            final hubGames = await gamesRepo.getGamesByHub(hub.hubId);
            allGames.addAll(hubGames);
          }
          games = allGames;
        }
      }

      // Group games by date (ignore time)
      final gamesByDate = <DateTime, List<Game>>{};
      for (final game in games) {
        final date = DateTime(
          game.gameDate.year,
          game.gameDate.month,
          game.gameDate.day,
        );
        gamesByDate.putIfAbsent(date, () => []).add(game);
      }

      setState(() {
        _gamesByDate = gamesByDate;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showError(context, 'שגיאה בטעינת משחקים: $e');
      }
    }
  }

  List<DateTime> _getDaysInMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final days = <DateTime>[];
    for (var i = firstDay.day; i <= lastDay.day; i++) {
      days.add(DateTime(month.year, month.month, i));
    }
    return days;
  }

  int _getFirstDayOfWeek(DateTime firstDay) {
    // Sunday = 0, Monday = 1, etc. In Hebrew, Sunday is first day
    return firstDay.weekday % 7;
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = _getDaysInMonth(_selectedMonth);
    final firstDay = daysInMonth.first;
    final firstDayOfWeek = _getFirstDayOfWeek(firstDay);
    final monthName = DateFormat('MMMM yyyy', 'he').format(_selectedMonth);

    return FuturisticScaffold(
      title: 'לוח שנה למשחקים',
      body: _isLoading
          ? ListView.builder(
              itemCount: 3,
              itemBuilder: (context, index) => const SkeletonGameCard(),
            )
          : Column(
        children: [
          // Month navigation
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() {
                        _selectedMonth = DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month - 1,
                        );
                      });
                      _loadGames();
                    },
                  ),
                  Text(
                    monthName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _selectedMonth = DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month + 1,
                        );
                      });
                      _loadGames();
                    },
                  ),
                ],
              ),
            ),
          ),
          // Calendar grid
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Weekday headers
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: ['א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ש'].map((day) {
                        return Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Calendar days
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // First row - may have empty cells
                        Row(
                          children: List.generate(7, (index) {
                            if (index < firstDayOfWeek) {
                              return const Expanded(child: SizedBox());
                            }
                            final dayIndex = index - firstDayOfWeek;
                            if (dayIndex >= daysInMonth.length) {
                              return const Expanded(child: SizedBox());
                            }
                            final date = daysInMonth[dayIndex];
                            return _buildDayCell(date);
                          }),
                        ),
                        // Remaining rows
                        ...List.generate(
                          (daysInMonth.length - (7 - firstDayOfWeek) + 6) ~/ 7,
                          (rowIndex) {
                            return Row(
                              children: List.generate(7, (colIndex) {
                                final dayIndex = (7 - firstDayOfWeek) +
                                    (rowIndex * 7) +
                                    colIndex;
                                if (dayIndex >= daysInMonth.length) {
                                  return const Expanded(child: SizedBox());
                                }
                                final date = daysInMonth[dayIndex];
                                return _buildDayCell(date);
                              }),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime date) {
    final isToday = date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;
    final isSelectedMonth = date.month == _selectedMonth.month;
    final games = _gamesByDate[date] ?? [];
    final hasGames = games.isNotEmpty;

    return Expanded(
      child: GestureDetector(
        onTap: hasGames
            ? () => _showGamesForDate(context, date, games)
            : null,
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isToday
                ? Colors.blue.withValues(alpha: 0.2)
                : hasGames
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.transparent,
            border: isToday
                ? Border.all(color: Colors.blue, width: 2)
                : hasGames
                    ? Border.all(color: Colors.green, width: 1)
                    : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isSelectedMonth ? Colors.white : Colors.grey,
                ),
              ),
              if (hasGames)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGamesForDate(BuildContext context, DateTime date, List<Game> games) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('dd/MM/yyyy', 'he').format(date),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...games.map((game) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.sports_soccer),
                  title: Text(
                    DateFormat('HH:mm', 'he').format(game.gameDate),
                  ),
                  subtitle: Text(game.location ?? 'מיקום לא צוין'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/games/${game.gameId}');
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

