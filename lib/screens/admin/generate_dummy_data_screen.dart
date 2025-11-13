import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kickadoor/widgets/futuristic/futuristic_scaffold.dart';
import 'package:kickadoor/widgets/futuristic/gradient_button.dart';
import 'package:kickadoor/scripts/generate_dummy_data.dart';
import 'package:kickadoor/utils/snackbar_helper.dart';

/// Screen for generating dummy data (admin only)
class GenerateDummyDataScreen extends ConsumerStatefulWidget {
  const GenerateDummyDataScreen({super.key});

  @override
  ConsumerState<GenerateDummyDataScreen> createState() => _GenerateDummyDataScreenState();
}

class _GenerateDummyDataScreenState extends ConsumerState<GenerateDummyDataScreen> {
  final _userCountController = TextEditingController(text: '30');
  final _hubCountController = TextEditingController(text: '5');
  bool _isGenerating = false;
  String? _statusMessage;

  @override
  void dispose() {
    _userCountController.dispose();
    _hubCountController.dispose();
    super.dispose();
  }

  Future<void> _generateData() async {
    final userCount = int.tryParse(_userCountController.text) ?? 30;
    final hubCount = int.tryParse(_hubCountController.text) ?? 5;

    if (userCount < 1 || hubCount < 1) {
      SnackbarHelper.showError(context, 'נא להזין מספרים תקינים');
      return;
    }

    setState(() {
      _isGenerating = true;
      _statusMessage = 'מתחיל ליצור נתוני דמה...';
    });

    try {
      final generator = DummyDataGenerator();
      await generator.generateAll(
        userCount: userCount,
        hubCount: hubCount,
      );

      if (mounted) {
        setState(() {
          _isGenerating = false;
          _statusMessage = '✅ נתוני דמה נוצרו בהצלחה!';
        });
        SnackbarHelper.showSuccess(
          context,
          'נוצרו $userCount שחקנים ו-$hubCount הובים',
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
          _statusMessage = '✅ Hub "השדים האדומים" נוצר בהצלחה עם 25 שחקנים (18 ב-Hub)!';
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

  @override
  Widget build(BuildContext context) {
    return FuturisticScaffold(
      title: 'יצירת נתוני דמה',
      body: Padding(
        padding: const EdgeInsets.all(24.0),
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
            // User count
            TextField(
              controller: _userCountController,
              decoration: const InputDecoration(
                labelText: 'מספר שחקנים',
                border: OutlineInputBorder(),
                helperText: 'מספר השחקנים ליצירה',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            // Hub count
            TextField(
              controller: _hubCountController,
              decoration: const InputDecoration(
                labelText: 'מספר הובים',
                border: OutlineInputBorder(),
                helperText: 'מספר ההובים ליצירה',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            // Generate button
            GradientButton(
              label: 'צור נתוני דמה',
              icon: Icons.auto_awesome,
              onPressed: _isGenerating ? null : _generateData,
              isLoading: _isGenerating,
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
          ],
        ),
      ),
    );
  }
}

