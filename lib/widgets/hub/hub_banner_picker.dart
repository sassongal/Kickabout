import 'package:flutter/material.dart';
import 'package:kattrick/theme/premium_theme.dart';

class HubBannerPicker extends StatefulWidget {
  final String? initialUrl;
  final ValueChanged<String> onBannerSelected;

  const HubBannerPicker({
    super.key,
    this.initialUrl,
    required this.onBannerSelected,
  });

  @override
  State<HubBannerPicker> createState() => _HubBannerPickerState();
}

class _HubBannerPickerState extends State<HubBannerPicker> {
  String? _currentUrl;
  final TextEditingController _urlController = TextEditingController();

  final List<String> _predefinedBanners = [
    'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&q=80&w=800', // Stadium night
    'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?auto=format&fit=crop&q=80&w=800', // Football grass
    'https://images.unsplash.com/photo-1517466787929-bc90951d0974?auto=format&fit=crop&q=80&w=800', // Players in action
    'https://images.unsplash.com/photo-1431324155629-1a6eda1eed2d?auto=format&fit=crop&q=80&w=800', // Soccer ball net
  ];

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialUrl;
    _urlController.text = _currentUrl ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'בחר באנר להוב',
          style: PremiumTypography.labelLarge
              .copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Preview
        if (_currentUrl != null && _currentUrl!.isNotEmpty)
          Container(
            height: 150,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(_currentUrl!),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: PremiumColors.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                ),
              ],
            ),
          )
        else
          Container(
            height: 150,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: PremiumColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: PremiumColors.primary.withValues(alpha: 0.3)),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image_outlined, size: 48, color: Colors.grey),
                  Text('אין באנר נבחר', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),

        // Predefined Options
        const Text('אפשרויות מוכנות',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _predefinedBanners.length,
            itemBuilder: (context, index) {
              final url = _predefinedBanners[index];
              final isSelected = _currentUrl == url;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _currentUrl = url;
                    _urlController.text = url;
                  });
                  widget.onBannerSelected(url);
                },
                child: Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? PremiumColors.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                    image: DecorationImage(
                      image: NetworkImage(url),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // Custom URL Input
        TextField(
          controller: _urlController,
          onChanged: (value) {
            setState(() {
              _currentUrl = value;
            });
            widget.onBannerSelected(value);
          },
          decoration: InputDecoration(
            labelText: 'או הזן כתובת תמונה מותאמת אישית',
            hintText: 'https://example.com/image.jpg',
            prefixIcon: const Icon(Icons.link),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
