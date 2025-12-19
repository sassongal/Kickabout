import 'package:flutter/material.dart';
import 'package:kattrick/utils/city_utils.dart';

/// City autocomplete field widget - reusable component for city selection
/// Uses CityUtils to provide list of cities and autocomplete suggestions
class CityAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String? initialValue;
  final ValueChanged<String>? onCitySelected;
  final bool required;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final IconData? prefixIcon;

  const CityAutocompleteField({
    super.key,
    required this.controller,
    this.initialValue,
    this.onCitySelected,
    this.required = false,
    this.labelText,
    this.hintText,
    this.helperText,
    this.prefixIcon,
  });

  @override
  State<CityAutocompleteField> createState() => _CityAutocompleteFieldState();
}

class _CityAutocompleteFieldState extends State<CityAutocompleteField> {
  @override
  void initState() {
    super.initState();
    // Set initial value if provided
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      widget.controller.text = widget.initialValue!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        // Filter cities that contain the input text
        return CityUtils.cities.where((String city) =>
            city.contains(textEditingValue.text));
      },
      onSelected: (String selection) {
        widget.controller.text = selection;
        if (widget.onCitySelected != null) {
          widget.onCitySelected!(selection);
        }
      },
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController textEditingController,
        FocusNode focusNode,
        VoidCallback onFieldSubmitted,
      ) {
        // Sync with external controller
        if (widget.controller.text.isNotEmpty &&
            textEditingController.text != widget.controller.text) {
          textEditingController.text = widget.controller.text;
        }

        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: widget.labelText ?? 'עיר',
            hintText: widget.hintText ?? 'חפש עיר...',
            helperText: widget.helperText,
            border: const OutlineInputBorder(),
            prefixIcon: Icon(widget.prefixIcon ?? Icons.location_city),
          ),
          onChanged: (value) {
            // Update external controller
            widget.controller.text = value;
          },
          validator: widget.required
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'יש לבחור עיר';
                  }
                  // Check if the city is in the list
                  if (!CityUtils.cities.contains(value.trim())) {
                    return 'עיר לא תקינה - בחר מהרשימה';
                  }
                  return null;
                }
              : null,
        );
      },
    );
  }
}
