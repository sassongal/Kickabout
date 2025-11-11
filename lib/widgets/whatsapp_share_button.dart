import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kickabout/core/constants.dart';

/// WhatsApp share button widget
class WhatsAppShareButton extends StatelessWidget {
  final String text;
  final String? phoneNumber;

  const WhatsAppShareButton({
    super.key,
    required this.text,
    this.phoneNumber,
  });

  Future<void> _shareToWhatsApp() async {
    try {
      // Try to open WhatsApp with deep link
      if (phoneNumber != null) {
        final url = '${AppConstants.whatsappWebUrl}/${AppConstants.whatsappPhonePrefix}${phoneNumber!.replaceAll(RegExp(r'[^0-9]'), '')}?text=${Uri.encodeComponent(text)}';
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          return;
        }
      }

      // Fallback to share_plus
      await Share.share(
        text,
        subject: 'Kickabout - סיכום משחק',
      );
    } catch (e) {
      // If share fails, try copy to clipboard
      await Clipboard.setData(ClipboardData(text: text));
    }
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _copyToClipboard,
            icon: const Icon(Icons.copy),
            label: const Text('העתק'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _shareToWhatsApp,
            icon: const Icon(Icons.share),
            label: const Text('שתף ב-WhatsApp'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

