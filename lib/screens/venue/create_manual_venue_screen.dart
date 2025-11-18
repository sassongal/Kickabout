import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickadoor/widgets/futuristic/futuristic_scaffold.dart';
import 'package:kickadoor/widgets/futuristic/futuristic_card.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/utils/snackbar_helper.dart';

/// Screen for creating a manual venue (not from Google Places)
class CreateManualVenueScreen extends ConsumerStatefulWidget {
  const CreateManualVenueScreen({super.key});

  @override
  ConsumerState<CreateManualVenueScreen> createState() => _CreateManualVenueScreenState();
}

class _CreateManualVenueScreenState extends ConsumerState<CreateManualVenueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  GeoPoint? _selectedLocation;
  String? _selectedAddress;
  bool _isPublic = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final result = await context.pushNamed<Map<String, dynamic>>(
      'mapPicker',
      extra: {'initialLocation': _selectedLocation},
    );

    if (result != null && result['location'] != null) {
      setState(() {
        _selectedLocation = result['location'] as GeoPoint;
        _selectedAddress = result['address'] as String?;
        // Update address field if available
        if (_selectedAddress != null && _addressController.text.isEmpty) {
          _addressController.text = _selectedAddress!;
        }
      });
    }
  }

  Future<void> _saveVenue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedLocation == null) {
      SnackbarHelper.showError(context, 'נא לבחור מיקום על המפה');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final venuesRepo = ref.read(venuesRepositoryProvider);
      final venue = await venuesRepo.createManualVenue(
        name: _nameController.text.trim(),
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        location: _selectedLocation!,
        isPublic: _isPublic,
      );

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'המגרש נוצר בהצלחה!');
        context.pop(venue); // Return the created venue
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'שגיאה ביצירת המגרש: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FuturisticScaffold(
      title: 'יצירת מגרש חדש',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FuturisticCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'פרטי המגרש',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'שם המגרש *',
                        hintText: 'לדוגמה: מגרש שכונתי - רחוב הרצל',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'נא להזין שם למגרש';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'כתובת',
                        hintText: 'כתובת מלאה (אופציונלי)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('מגרש ציבורי'),
                      subtitle: const Text('מגרש ציבורי זמין לכל המשתמשים'),
                      value: _isPublic,
                      onChanged: (value) {
                        setState(() {
                          _isPublic = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FuturisticCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'מיקום',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_selectedLocation != null) ...[
                      Text(
                        'מיקום נבחר:',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedAddress ??
                            '${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else
                      Text(
                        'לא נבחר מיקום',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _pickLocation,
                      icon: const Icon(Icons.map),
                      label: Text(_selectedLocation == null
                          ? 'בחר מיקום על המפה'
                          : 'שנה מיקום'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveVenue,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('שמור מגרש'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

