import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/utils/city_utils.dart';
import 'package:kattrick/widgets/input/city_autocomplete_field.dart';

/// Hub City Selector - allows managers to set the hub's primary city
class HubCitySelector extends ConsumerStatefulWidget {
  final String hubId;
  final Hub hub;

  const HubCitySelector({
    super.key,
    required this.hubId,
    required this.hub,
  });

  @override
  ConsumerState<HubCitySelector> createState() => _HubCitySelectorState();
}

class _HubCitySelectorState extends ConsumerState<HubCitySelector> {
  final TextEditingController _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cityController.text = widget.hub.city ?? '';
  }

  @override
  void didUpdateWidget(HubCitySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hub.city != oldWidget.hub.city) {
      _cityController.text = widget.hub.city ?? '';
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _saveCity(String city) async {
    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);
      final region = CityUtils.getRegionForCity(city);

      await hubsRepo.updateHub(
        widget.hubId,
        {
          'city': city,
          'region': region,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('העיר עודכנה בהצלחה!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בעדכון העיר: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCityDialog() {
    final tempController = TextEditingController(text: widget.hub.city ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('בחר עיר'),
        content: SizedBox(
          width: double.maxFinite,
          child: CityAutocompleteField(
            controller: tempController,
            labelText: 'עיר ראשית של ההאב',
            hintText: 'בחר עיר...',
            helperText: 'האזור יחושב אוטומטית',
            onCitySelected: (city) {
              // City selected
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () {
              final city = tempController.text.trim();
              if (city.isNotEmpty) {
                Navigator.pop(context);
                _saveCity(city);
              }
            },
            child: const Text('שמור'),
          ),
        ],
      ),
    ).then((_) => tempController.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.location_city,
              size: 24,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'עיר',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.hub.city ?? 'לא נבחר',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.hub.region != null)
                    Text(
                      'אזור: ${widget.hub.region}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: _showCityDialog,
              tooltip: widget.hub.city != null ? 'ערוך עיר' : 'בחר עיר',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
