import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/models/venue.dart';
import 'package:kattrick/widgets/input/smart_venue_search_field.dart';
import 'package:kattrick/theme/futuristic_theme.dart';

/// Widget to manage Hub venues (add, remove, set primary)
class HubVenuesManager extends ConsumerStatefulWidget {
  final List<Venue> initialVenues;
  final String? initialMainVenueId;
  final Function(List<Venue> venues, String? mainVenueId) onChanged;

  const HubVenuesManager({
    super.key,
    this.initialVenues = const [],
    this.initialMainVenueId,
    required this.onChanged,
  });

  @override
  ConsumerState<HubVenuesManager> createState() => _HubVenuesManagerState();
}

class _HubVenuesManagerState extends ConsumerState<HubVenuesManager> {
  late List<Venue> _selectedVenues;
  String? _mainVenueId;

  @override
  void initState() {
    super.initState();
    _selectedVenues = List.from(widget.initialVenues);
    _mainVenueId = widget.initialMainVenueId;

    // Ensure we have a main venue if venues exist
    if (_selectedVenues.isNotEmpty && _mainVenueId == null) {
      _mainVenueId = _selectedVenues.first.venueId;
    }
  }

  void _addVenue(Venue venue) {
    if (_selectedVenues.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ניתן להוסיף עד 3 מגרשים ל-Hub')),
      );
      return;
    }

    if (_selectedVenues.any((v) => v.venueId == venue.venueId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('המגרש כבר קיים ברשימה')),
      );
      return;
    }

    setState(() {
      _selectedVenues.add(venue);
      // If this is the first venue, make it main
      if (_selectedVenues.length == 1) {
        _mainVenueId = venue.venueId;
      }
    });

    widget.onChanged(_selectedVenues, _mainVenueId);
  }

  void _removeVenue(Venue venue) {
    setState(() {
      _selectedVenues.removeWhere((v) => v.venueId == venue.venueId);

      // If we removed the main venue, pick a new one if possible
      if (_mainVenueId == venue.venueId) {
        if (_selectedVenues.isNotEmpty) {
          _mainVenueId = _selectedVenues.first.venueId;
        } else {
          _mainVenueId = null;
        }
      }
    });

    widget.onChanged(_selectedVenues, _mainVenueId);
  }

  void _setMainVenue(String venueId) {
    setState(() {
      _mainVenueId = venueId;
    });
    widget.onChanged(_selectedVenues, _mainVenueId);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'מגרשי הבית (עד 3)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // Search field (only if less than 3 venues)
        if (_selectedVenues.length < 3)
          SmartVenueSearchField(
            onVenueSelected: _addVenue,
            label: 'הוסף מגרש',
            hint: 'חפש מגרש להוספה...',
          ),

        const SizedBox(height: 16),

        // List of selected venues
        if (_selectedVenues.isEmpty)
          const Text(
            'לא נבחרו מגרשים. הוסף מגרש כדי להתחיל.',
            style: TextStyle(color: Colors.grey),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _selectedVenues.length,
            itemBuilder: (context, index) {
              final venue = _selectedVenues[index];
              final isMain = venue.venueId == _mainVenueId;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isMain
                      ? BorderSide(color: FuturisticColors.primary, width: 2)
                      : BorderSide.none,
                ),
                child: ListTile(
                  leading: Radio<String>(
                    value: venue.venueId,
                    groupValue: _mainVenueId,
                    onChanged: (value) {
                      if (value != null) _setMainVenue(value);
                    },
                  ),
                  title: Text(venue.name),
                  subtitle: Text(venue.address ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeVenue(venue),
                  ),
                  onTap: () => _setMainVenue(venue.venueId),
                ),
              );
            },
          ),

        if (_selectedVenues.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '* המגרש המסומן הוא המגרש הראשי של ה-Hub',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
      ],
    );
  }
}
