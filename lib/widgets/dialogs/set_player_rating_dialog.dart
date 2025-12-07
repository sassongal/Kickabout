import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kattrick/data/hubs_repository.dart';

/// Dialog for setting a player's rating within a hub
class SetPlayerRatingDialog extends StatefulWidget {
  final String hubId;
  final String playerId;
  final String playerName;
  final double? currentRating;

  const SetPlayerRatingDialog({
    super.key,
    required this.hubId,
    required this.playerId,
    required this.playerName,
    this.currentRating,
  });

  @override
  State<SetPlayerRatingDialog> createState() => _SetPlayerRatingDialogState();
}

class _SetPlayerRatingDialogState extends State<SetPlayerRatingDialog> {
  final TextEditingController _ratingController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  double _sliderValue = 5.0;

  @override
  void initState() {
    super.initState();
    // Initialize with current rating or 4.0 default (middle of 1-7 scale)
    _sliderValue = widget.currentRating ?? 4.0;
    _ratingController.text = _sliderValue.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _ratingController.dispose();
    super.dispose();
  }

  void _updateSlider(String value) {
    final parsed = double.tryParse(value);
    if (parsed != null && parsed >= 1.0 && parsed <= 7.0) {
      setState(() {
        _sliderValue = parsed;
      });
    }
  }

  void _updateTextField(double value) {
    _ratingController.text = value.toStringAsFixed(1);
  }

  Future<void> _saveRating() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final rating = double.parse(_ratingController.text);
      final hubsRepo = HubsRepository();

      await hubsRepo.setPlayerRating(widget.hubId, widget.playerId, rating);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בשמירת דירוג: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildRatingGuideRow(
      String range, String level, String description, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    range,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    level,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.star, color: theme.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'דירוג שחקן',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Player name
              Text(
                widget.playerName,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Rating slider
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('1.0', style: theme.textTheme.bodySmall),
                      Text(
                        _sliderValue.toStringAsFixed(1),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('7.0', style: theme.textTheme.bodySmall),
                    ],
                  ),
                  Slider(
                    value: _sliderValue,
                    min: 1.0,
                    max: 7.0,
                    divisions: 12, // 0.5 increments (6 steps × 2 = 12 divisions)
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            setState(() {
                              _sliderValue = value;
                            });
                            _updateTextField(value);
                          },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Manual input field
              TextFormField(
                controller: _ratingController,
                enabled: !_isLoading,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
                ],
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'דירוג (1.0 - 7.0)',
                  prefixIcon: Icon(Icons.edit),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'נא להזין דירוג';
                  }
                  final rating = double.tryParse(value);
                  if (rating == null) {
                    return 'נא להזין מספר תקין';
                  }
                  if (rating < 1.0 || rating > 7.0) {
                    return 'דירוג חייב להיות בין 1.0 ל-7.0';
                  }
                  // Validate 0.5 increments
                  final remainder = (rating * 2) % 1;
                  if (remainder != 0.0) {
                    return 'דירוג חייב להיות במדרגות של 0.5 (למשל: 3.5, 4.0, 5.5)';
                  }
                  return null;
                },
                onChanged: _updateSlider,
              ),
              const SizedBox(height: 24),

              // Info text with rating guide
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 20, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'דירוג זה ישמש ליצירת קבוצות מאוזנות במשחקים של ההאב',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Rating scale guide
                  ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                    title: Row(
                      children: [
                        const Icon(Icons.help_outline, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'מדריך לסקלת הדירוג',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildRatingGuideRow('1.0 - 2.5', 'מתחיל',
                                'שחקן חדש או עם ניסיון מועט', Colors.red),
                            const SizedBox(height: 8),
                            _buildRatingGuideRow('3.0 - 5.0', 'בינוני',
                                'שחקן עם יכולות סבירות, משחק באופן קבוע', Colors.orange),
                            const SizedBox(height: 8),
                            _buildRatingGuideRow('5.5 - 7.0', 'מתקדם',
                                'שחקן מנוסה עם יכולות גבוהות', Colors.green),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
                            Text(
                              'טיפ: השתמש בחצאי נקודות (0.5) כדי לדייק את הדירוג',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('ביטול'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveRating,
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('שמור'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
