import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kattrick/models/models.dart';
import 'package:url_launcher/url_launcher.dart';

class HubSharingUtils {
  static Future<void> shareHubOnWhatsApp(BuildContext context, Hub hub) async {
    try {
      // Generate deep link
      final deepLink = 'kattrick://hub/${hub.hubId}';
      final webLink =
          'https://kattrick.app/hub/${hub.hubId}'; // Fallback web link

      final message =
          'בוא לשחק איתנו ב-${hub.name}!\nהצטרף כאן: $webLink\n\n$deepLink';

      final uri = Uri.parse(
        'https://wa.me/?text=${Uri.encodeComponent(message)}',
      );

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: copy to clipboard
        await Clipboard.setData(ClipboardData(text: message));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('הקישור הועתק ללוח'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error sharing hub on WhatsApp: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('שגיאה בשיתוף'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
