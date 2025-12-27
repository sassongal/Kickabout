import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kattrick/widgets/input/city_autocomplete_field.dart';
import 'package:kattrick/features/location/infrastructure/services/location_service.dart';
import 'package:geolocator/geolocator.dart';

/// Non-dismissible city selection dialog for GPS-denied users
///
/// This dialog is shown when:
/// 1. GPS permission is denied
/// 2. No cached city exists in SharedPreferences
/// 3. User is accessing a map screen for the first time
///
/// The dialog is non-dismissible (cannot be closed with back button or tap outside)
/// until a city is selected. This ensures the map always has a valid center point.
///
/// Usage:
/// ```dart
/// final city = await showCitySelectionDialog(context);
/// ```
class CitySelectionDialog extends StatefulWidget {
  /// Whether this is the first time the user is seeing this dialog
  final bool isFirstTime;

  const CitySelectionDialog({
    super.key,
    this.isFirstTime = true,
  });

  @override
  State<CitySelectionDialog> createState() => _CitySelectionDialogState();
}

class _CitySelectionDialogState extends State<CitySelectionDialog> {
  final _cityController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  /// Save selected city to SharedPreferences
  Future<void> _saveCity(String city) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_city', city);
    } catch (e) {
      debugPrint('Error saving city to cache: $e');
    }
  }

  /// Handle city selection and convert to coordinates
  Future<void> _handleCitySelection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final city = _cityController.text.trim();

      // Save city to cache
      await _saveCity(city);

      // Convert city to coordinates using LocationService
      final locationService = LocationService();
      final position = await locationService.getLocationFromAddress(city);

      if (!mounted) return;

      if (position != null) {
        // Return the position to the caller
        Navigator.of(context).pop(position);
      } else {
        // Show error if geocoding failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('לא הצלחנו למצוא את העיר "$city". נסה עיר אחרת.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('שגיאה בבחירת עיר: $e'),
          backgroundColor: Colors.red,
        ),
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Prevent back button from closing dialog
      canPop: false,
      child: Dialog(
        // Non-dismissible
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon
                Icon(
                  Icons.location_city,
                  size: 48,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  widget.isFirstTime
                      ? 'בחר את העיר שלך'
                      : 'לא ניתן לגשת למיקום',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  widget.isFirstTime
                      ? 'כדי להציג מגרשים והאבים קרובים, אנא בחר את העיר בה אתה נמצא.'
                      : 'לא ניתן לגשת לשירותי המיקום. אנא בחר עיר ידנית כדי להמשיך.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // City autocomplete field
                CityAutocompleteField(
                  controller: _cityController,
                  required: true,
                  labelText: 'עיר',
                  hintText: 'חפש עיר...',
                  helperText: 'בחר עיר מהרשימה',
                  prefixIcon: Icons.search,
                ),
                const SizedBox(height: 24),

                // Confirm button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleCitySelection,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'המשך',
                          style: TextStyle(fontSize: 16),
                        ),
                ),

                // Info text
                const SizedBox(height: 16),
                Text(
                  'הבחירה תישמר ותשמש כברירת מחדל בפעם הבאה',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Show city selection dialog
///
/// Returns the Position for the selected city, or null if cancelled.
/// Dialog is non-dismissible, so user must select a city.
Future<Position?> showCitySelectionDialog(
  BuildContext context, {
  bool isFirstTime = true,
}) async {
  return showDialog<Position>(
    context: context,
    barrierDismissible: false, // Cannot dismiss by tapping outside
    builder: (context) => CitySelectionDialog(isFirstTime: isFirstTime),
  );
}
