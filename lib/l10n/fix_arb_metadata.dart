import 'dart:convert';
import 'dart:io';

/// A script to automatically add missing metadata entries to ARB files.
///
/// Run from the terminal:
/// `dart run tool/fix_arb_metadata.dart path/to/your/app_en.arb`
void main(List<String> arguments) {
  if (arguments.isEmpty) {
    print('Usage: dart run tool/fix_arb_metadata.dart <path_to_arb_file>');
    exit(1);
  }

  for (final path in arguments) {
    final file = File(path);
    if (!file.existsSync()) {
      print('Error: File not found at $path');
      continue;
    }

    print('Processing $path...');
    final content = file.readAsStringSync();
    final jsonMap = json.decode(content) as Map<String, dynamic>;

    // Use a copy of keys to avoid modification errors during iteration
    final keys = jsonMap.keys.toList();
    int addedCount = 0;

    for (final key in keys) {
      // Skip metadata keys themselves
      if (key.startsWith('@')) continue;

      final metadataKey = '@$key';
      if (!jsonMap.containsKey(metadataKey)) {
        // Insert the new metadata key right after the original key
        jsonMap[metadataKey] = <String, dynamic>{};
        addedCount++;
      }
    }

    final encoder = JsonEncoder.withIndent('  ');
    final newContent = encoder.convert(jsonMap);
    file.writeAsStringSync(newContent);
    print('Done. Added $addedCount missing metadata entries to $path.');
  }
}
