import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/widgets/futuristic/futuristic_scaffold.dart';
import 'package:kattrick/widgets/futuristic/gradient_button.dart';
import 'package:kattrick/scripts/generate_dummy_data.dart';
import 'package:kattrick/scripts/team_balancing_test_script.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kattrick/utils/venue_seeder_service.dart';

/// Screen for generating dummy data (admin only)
class GenerateDummyDataScreen extends ConsumerStatefulWidget {
  const GenerateDummyDataScreen({super.key});

  @override
  ConsumerState<GenerateDummyDataScreen> createState() =>
      _GenerateDummyDataScreenState();
}

class _GenerateDummyDataScreenState
    extends ConsumerState<GenerateDummyDataScreen> {
  final _userCountController = TextEditingController(text: '30');

  final _targetHubIdController =
      TextEditingController(text: '4E3bIBPVKdcx5Z1gKfCT');
  final _targetEventIdController =
      TextEditingController(text: 'OTd8UEnHI1jVVxsHYcrW');

  bool _isGenerating = false;
  String? _statusMessage;

  // Last created test scenario (for cleanup)
  String? _lastTestHubId;
  String? _lastTestEventId;
  List<String>? _lastTestPlayerIds;

  @override
  void dispose() {
    _userCountController.dispose();

    _targetHubIdController.dispose();
    _targetEventIdController.dispose();
    super.dispose();
  }

  Future<void> _generateData() async {
    final userCount = int.tryParse(_userCountController.text) ?? 30;
    final hubId = _targetHubIdController.text.trim();
    final eventId = _targetEventIdController.text.trim();

    if (hubId.isEmpty) {
      SnackbarHelper.showError(context, 'נא להזין מזהה Hub (ID) באזור למטה.');
      return;
    }
    if (userCount < 1) {
      SnackbarHelper.showError(context, 'נא להזין מספר שחקנים תקין.');
      return;
    }

    setState(() {
      _isGenerating = true;
      _statusMessage =
          'מוסיף $userCount שחקנים ל-Hub $hubId ורושם אותם לאירוע $eventId...';
    });

    try {
      final generator = DummyDataGenerator();
      await generator.addPlayersToExistingHub(
        hubId: hubId,
        count: userCount,
        eventId: eventId,
      );

      if (mounted) {
        setState(() {
          _isGenerating = false;
          _statusMessage =
              '✅ $userCount שחקנים נוספו בהצלחה ל-Hub ונרשמו לאירוע!';
        });
        SnackbarHelper.showSuccess(
          context,
          'נוספו $userCount שחקנים ל-Hub ונרשמו לאירוע',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _statusMessage = '❌ שגיאה: $e';
        });
        SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }

  Future<void> _generateRealFieldHubs() async {
    setState(() {
      _isGenerating = true;
      _statusMessage = 'מתחיל ליצור Hubs במגרשים אמיתיים...';
    });

    try {
      final generator = DummyDataGenerator();
      await generator.generateRealFieldHubs(playersPerHub: 15);

      if (mounted) {
        setState(() {
          _isGenerating = false;
          _statusMessage = '✅ Hubs במגרשים אמיתיים נוצרו בהצלחה!';
        });
        SnackbarHelper.showSuccess(
          context,
          'נוצרו 5 Hubs במגרשים: גן דניאל, ספורטן, קצף, מרכז הטניס, רוממה-ביה"ס',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _statusMessage = '❌ שגיאה: $e';
        });
        SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }

  Future<void> _generateRedDevilsHub() async {
    setState(() {
      _isGenerating = true;
      _statusMessage = 'מתחיל ליצור Hub "השדים האדומים" עם 25 שחקנים...';
    });

    try {
      final generator = DummyDataGenerator();
      await generator.generateRedDevilsHub();

      if (mounted) {
        setState(() {
          _isGenerating = false;
          _statusMessage =
              '✅ Hub "השדים האדומים" נוצר בהצלחה עם 25 שחקנים (18 ב-Hub)!';
        });
        SnackbarHelper.showSuccess(
          context,
          'נוצר Hub "השדים האדומים" עם 18 שחקנים + 7 שחקנים נוספים',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _statusMessage = '❌ שגיאה: $e';
        });
        SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }

  Future<void> _generateHaifaScenario() async {
    setState(() {
      _isGenerating = true;
      _statusMessage = 'מתחיל ליצור תרחיש חיפה...';
    });

    try {
      final generator = DummyDataGenerator();
      await generator.generateHaifaScenario();

      if (mounted) {
        setState(() {
          _isGenerating = false;
          _statusMessage =
              '✅ תרחיש חיפה נוצר בהצלחה!\n• 30 שחקנים\n• 6 הובים במיקומים ספציפיים\n• כל Hub עם 5 שחקנים (1 מנהל, 4 שחקנים)';
        });
        SnackbarHelper.showSuccess(
          context,
          'נוצר תרחיש חיפה: 30 שחקנים ו-6 הובים',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _statusMessage = '❌ שגיאה: $e';
        });
        SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }

  Future<void> _seedVenues() async {
    setState(() {
      _isGenerating = true;
      _statusMessage = 'מאכלס מגרשים בערים מרכזיות...';
    });

    try {
      final seeder = ref.read(venueSeederServiceProvider);
      await seeder.seedMajorCities();

      if (mounted) {
        setState(() {
          _isGenerating = false;
          _statusMessage = '✅ אכלוס מגרשים הסתיים בהצלחה!';
        });
        SnackbarHelper.showSuccess(
          context,
          'אכלוס מגרשים הסתיים בהצלחה!',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _statusMessage = '❌ שגיאה: $e';
        });
        SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }

  Future<void> _deleteAllDummyData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחיקת כל נתוני הדמה'),
        content: const Text(
          'האם אתה בטוח שברצונך למחוק את כל נתוני הדמה? פעולה זו אינה הפיכה.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('מחק הכל'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isGenerating = true;
      _statusMessage = 'מתחיל למחוק נתוני דמה...';
    });

    try {
      final generator = DummyDataGenerator();
      await generator.deleteAllDummyData();

      if (mounted) {
        setState(() {
          _isGenerating = false;
          _statusMessage = '✅ כל נתוני הדמה נמחקו בהצלחה!';
        });
        SnackbarHelper.showSuccess(
          context,
          'כל נתוני הדמה נמחקו',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _statusMessage = '❌ שגיאה: $e';
        });
        SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }

  Future<void> _generateComprehensiveData() async {
    setState(() {
      _isGenerating = true;
      _statusMessage =
          'מתחיל ליצור נתונים מקיפים (20 שחקנים, 3 הובים, 15 משחקי עבר)...';
    });

    try {
      final generator = DummyDataGenerator();
      await generator.generateComprehensiveData();

      if (mounted) {
        setState(() {
          _isGenerating = false;
          _statusMessage =
              '✅ נתונים מקיפים נוצרו בהצלחה!\n• 20 שחקנים עם תמונות וסגנונות משחק\n• 3 הובים עם מנהלים\n• 15 משחקי עבר עם תוצאות וסטטיסטיקות';
        });
        SnackbarHelper.showSuccess(
          context,
          'נוצרו 20 שחקנים, 3 הובים, ו-15 משחקי עבר עם סטטיסטיקות!',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _statusMessage = '❌ שגיאה: $e';
        });
        SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }

  Future<void> _generateTeamBalancingTest() async {
    setState(() {
      _isGenerating = true;
      _statusMessage = 'מתחיל ליצור תרחיש בדיקת איזון קבוצות...';
    });

    try {
      final script = TeamBalancingTestScript();
      final result = await script.createCompleteTestScenario();

      if (mounted) {
        setState(() {
          _isGenerating = false;
          // שמירת IDs למחיקה מאוחר יותר
          _lastTestHubId = result['hubId'] as String?;
          _lastTestEventId = result['eventId'] as String?;
          _lastTestPlayerIds = (result['playerIds'] as List?)?.cast<String>();

          _statusMessage = '✅ תרחיש איזון קבוצות נוצר בהצלחה!\n'
              '🏟️ Hub ID: ${result['hubId']}\n'
              '📅 Event ID: ${result['eventId']}\n'
              '👥 15 שחקנים רשומים ואישרו הגעה\n'
              '📈 טווח דירוגים: 4.2 - 8.5';
        });
        SnackbarHelper.showSuccess(
          context,
          'נוצר Hub + 15 שחקנים + אירוע עם 3 קבוצות (Winner Stays)',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _statusMessage = '❌ שגיאה: $e';
        });
        SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }

  /// Create complete team balance scenario: Hub + Event + 15 confirmed players
  /// with current user as manager
  Future<void> _createTeamBalanceScenario() async {
    setState(() {
      _isGenerating = true;
      _statusMessage = 'יוצר תרחיש איזון קבOצות...';
    });

    try {
      final generator = DummyDataGenerator();
      final result = await generator.createTeamBalanceScenario();

      if (!mounted) return;

      setState(() {
        _isGenerating = false;
        _statusMessage = '''✅ תרחיש נוצר בהצלחה!
        
🏟️ האב: ${result['hubName']}
📅 אירוע: ${result['eventTitle']}
👥 15 שחקנים מאושרים (כולל אתה כמנהל)
        
מנווט לאירוע...''';
      });

      // Navigate to the hub
      final hubId = result['hubId']!;

      // Delay to show success message
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // Navigate to hub
      context.push('/hubs/$hubId');

      SnackbarHelper.showSuccess(
        context,
        'תרחיש נוצר! לחץ על האירוע כדי ליצור קבוצות',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isGenerating = false;
        _statusMessage = 'שגיאה: ${e.toString()}';
      });

      SnackbarHelper.showError(context, 'שגיאה ביצירת תרחיש: ${e.toString()}');
    }
  }

  Future<void> _cleanupLastTestScenario() async {
    if (_lastTestHubId == null ||
        _lastTestEventId == null ||
        _lastTestPlayerIds == null) {
      SnackbarHelper.showWarning(context, 'אין תרחיש בדיקה זמין למחיקה');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחיקת תרחיש בדיקה'),
        content: Text(
          'האם אתה בטוח שברצונך למחוק את תרחיש הבדיקה?\n\n'
          '🏟️ Hub: $_lastTestHubId\n'
          '📅 אירוע: $_lastTestEventId\n'
          '👥 ${(_lastTestPlayerIds?.length ?? 0) - 1} שחקנים דמה',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('מחק'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isGenerating = true;
      _statusMessage = 'מוחק תרחיש בדיקה...';
    });

    try {
      final script = TeamBalancingTestScript();

      // מחיקת השחקנים הדמה בלבד (לא המנהל הנוכחי)
      final dummyPlayerIds =
          _lastTestPlayerIds!.skip(1).toList(); // דילוג על המנהל

      await script.cleanupTestScenario(
        hubId: _lastTestHubId!,
        eventId: _lastTestEventId!,
        playerIds: dummyPlayerIds,
      );

      if (!mounted) return;

      setState(() {
        _isGenerating = false;
        _statusMessage = '✅ תרחיש הבדיקה נמחק בהצלחה!';
        // איפוס ה-IDs
        _lastTestHubId = null;
        _lastTestEventId = null;
        _lastTestPlayerIds = null;
      });
      SnackbarHelper.showSuccess(context, 'תרחיש הבדיקה נמחק');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isGenerating = false;
        _statusMessage = '❌ שגיאה במחיקה: $e';
      });
      SnackbarHelper.showErrorFromException(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FuturisticScaffold(
      title: 'יצירת נתוני דמה',
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'יצירת נתוני דמה לאפליקציה',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'יצירת שחקנים והובים מחיפה והאיזור עם פעילות',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              Card(
                color: Colors.blue.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.group_add, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'הוספת שחקנים ל-Hub ואירוע',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _userCountController,
                        decoration: const InputDecoration(
                          labelText: 'מספר שחקנים ליצירה',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_add_alt_1),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _targetHubIdController,
                        decoration: const InputDecoration(
                          labelText: 'Hub ID',
                          hintText: 'הדבק כאן את המזהה של ה-Hub',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.hub),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _targetEventIdController,
                        decoration: const InputDecoration(
                          labelText: 'Event ID',
                          hintText: 'הדבק כאן את מזהה האירוע',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.event),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GradientButton(
                        label: 'הוסף שחקנים והירשם לאירוע',
                        icon: Icons.auto_awesome,
                        onPressed: _isGenerating ? null : _generateData,
                        isLoading: _isGenerating,
                        width: double.infinity,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'אפשרויות נוספות:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Comprehensive data generation button (NEW - recommended)
              GradientButton(
                label: 'צור נתונים מקיפים (מומלץ)',
                icon: Icons.star,
                onPressed: _isGenerating ? null : _generateComprehensiveData,
                isLoading: _isGenerating,
              ),
              const SizedBox(height: 16),
              // Team Balancing Test button (NEW - for testing team generation)
              Card(
                color: Colors.green.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.balance, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'בדיקת איזון קבוצות ⚖️',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'יוצר Hub חדש + 15 שחקנים + אירוע עם 3 קבוצות (Winner Stays)',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      GradientButton(
                        label: 'צור תרחיש בדיקת איזון קבוצות',
                        icon: Icons.sports_soccer,
                        onPressed:
                            _isGenerating ? null : _generateTeamBalancingTest,
                        isLoading: _isGenerating,
                        width: double.infinity,
                        gradient: const LinearGradient(
                          colors: [Colors.green, Colors.lightGreen],
                        ),
                      ),
                      if (_lastTestHubId != null) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.info_outline,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'תרחיש אחרון נוצר: Hub $_lastTestHubId',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed:
                              _isGenerating ? null : _cleanupLastTestScenario,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('מחק תרחיש אחרון'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade100,
                            foregroundColor: Colors.red.shade900,
                            minimumSize: const Size(double.infinity, 42),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // NEW: Team Balance Scenario with current user
              Card(
                color: Colors.purple.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.groups, color: Colors.purple),
                          SizedBox(width: 8),
                          Text(
                            'תרחיש איזון קבוצות - אתה מנהל 👑',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'יוצר האב חדש + 15 שחקנים מאושרים + אירוע, כאשר אתה המנהל וגם אחד מהשחקנים',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      GradientButton(
                        label: 'צור תרחיש איזון קבוצות',
                        icon: Icons.auto_awesome,
                        onPressed:
                            _isGenerating ? null : _createTeamBalanceScenario,
                        isLoading: _isGenerating,
                        width: double.infinity,
                        gradient: const LinearGradient(
                          colors: [Colors.purple, Colors.deepPurple],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Generate real field hubs button
              GradientButton(
                label: 'צור Hubs במגרשים אמיתיים',
                icon: Icons.stadium,
                onPressed: _isGenerating ? null : _generateRealFieldHubs,
                isLoading: _isGenerating,
              ),
              const SizedBox(height: 16),
              // Generate Red Devils Hub button
              GradientButton(
                label: 'צור Hub "השדים האדומים" עם 25 שחקנים',
                icon: Icons.people,
                onPressed: _isGenerating ? null : _generateRedDevilsHub,
                isLoading: _isGenerating,
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'תרחיש חיפה (מומלץ לבדיקות):',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'יוצר 30 שחקנים ו-6 הובים במיקומים ספציפיים בחיפה',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 12),
              GradientButton(
                label: 'צור תרחיש חיפה',
                icon: Icons.location_city,
                onPressed: _isGenerating ? null : _generateHaifaScenario,
                isLoading: _isGenerating,
                width: double.infinity,
                gradient: const LinearGradient(
                  colors: [Colors.green, Colors.greenAccent],
                ),
              ),
              const SizedBox(height: 16),
              GradientButton(
                label: 'אכלס מגרשים (ערים מרכזיות)',
                icon: Icons.stadium,
                onPressed: _isGenerating ? null : _seedVenues,
                isLoading: _isGenerating,
                width: double.infinity,
                gradient: const LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange],
                ),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'ניהול נתוני דמה:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isGenerating ? null : _deleteAllDummyData,
                icon: const Icon(Icons.delete_forever),
                label: const Text('מחק כל נתוני דמה'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              if (_statusMessage != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusMessage!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'מה יווצר:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• שחקנים עם שמות ישראליים'),
              const Text('• הובים מחיפה והאיזור'),
              const Text('• משחקים (עבר ועתיד)'),
              const Text('• פוסטים בפיד'),
              const Text('• מיקומים גיאוגרפיים'),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'הגדרות מערכת:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Reset Onboarding button
              GradientButton(
                label: 'איפוס Onboarding (לצורך בדיקה)',
                icon: Icons.refresh,
                onPressed: _isGenerating ? null : _resetOnboarding,
                isLoading: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Reset welcome/onboarding status - useful for testing
  Future<void> _resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('onboarding_completed'); // legacy
      await prefs.remove('has_seen_welcome'); // new flow

      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          '✅ Welcome אופס! בפעם הבאה שתריץ את האפליקציה, מסך הפתיחה יוצג שוב.',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'שגיאה באיפוס Welcome: $e');
      }
    }
  }
}
