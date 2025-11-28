import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/venue.dart';

/// A reusable widget for searching venues with smart autocomplete.
///
/// Features:
/// - Searches both Firestore and Google Places
/// - Displays distinct icons for Verified (Firestore) vs. Discovery (Google) results
/// - Automatically saves Google results to Firestore upon selection
class SmartVenueSearchField extends ConsumerStatefulWidget {
  final Function(Venue) onVenueSelected;
  final String? initialValue;
  final String label;
  final String hint;

  const SmartVenueSearchField({
    super.key,
    required this.onVenueSelected,
    this.initialValue,
    this.label = 'כתובת או שם מגרש',
    this.hint = 'חפש מגרש קהילתי/פרטי/ציבורי...',
  });

  @override
  ConsumerState<SmartVenueSearchField> createState() =>
      _SmartVenueSearchFieldState();
}

class _SmartVenueSearchFieldState extends ConsumerState<SmartVenueSearchField> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(SmartVenueSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<Venue>(
          textEditingController: _controller,
          focusNode: _focusNode,
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.length < 2) {
              return const Iterable<Venue>.empty();
            }
            return await ref
                .read(venuesRepositoryProvider)
                .searchVenuesCombined(textEditingValue.text);
          },
          displayStringForOption: (Venue option) => option.name,
          onSelected: (Venue selection) async {
            Venue venue = selection;
            // If it's a Google result (empty ID), save it
            if (venue.venueId.isEmpty) {
              try {
                venue = await ref
                    .read(venuesRepositoryProvider)
                    .getOrCreateVenueFromGooglePlace(selection);
              } catch (e) {
                debugPrint('Error creating venue: $e');
              }
            }

            _controller.text = venue.name;
            widget.onVenueSelected(venue);

            // Unfocus to close keyboard
            _focusNode.unfocus();
          },
          optionsViewBuilder: (BuildContext context,
              AutocompleteOnSelected<Venue> onSelected,
              Iterable<Venue> options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: 200.0,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Venue option = options.elementAt(index);
                      return ListTile(
                        leading: Icon(
                          option.venueId.isNotEmpty
                              ? Icons.verified
                              : Icons.map,
                          color: option.venueId.isNotEmpty
                              ? Colors.blue
                              : Colors.grey,
                        ),
                        title: Text(option.name),
                        subtitle: Text(option.address ?? ''),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
          fieldViewBuilder: (BuildContext context,
              TextEditingController textEditingController,
              FocusNode focusNode,
              VoidCallback onFieldSubmitted) {
            return TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: widget.label,
                hintText: widget.hint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                helperText: 'הקלד שם/כתובת כדי ששחקנים יוכלו לנווט לשם',
              ),
              onFieldSubmitted: (String value) {
                onFieldSubmitted();
              },
            );
          },
        );
      },
    );
  }
}
