import 'package:flutter_test/flutter_test.dart';
import 'package:kickabout/models/user.dart';

void main() {
  group('User Model', () {
    test('should create User from JSON', () {
      final json = {
        'uid': 'user123',
        'name': 'Test User',
        'email': 'test@example.com',
        'createdAt': DateTime.now().toIso8601String(),
        'hubIds': [],
        'currentRankScore': 5.0,
        'preferredPosition': 'Midfielder',
      };

      // TODO: Add test after build_runner generates code
      // final user = User.fromJson(json);
      // expect(user.uid, 'user123');
    });

    test('should convert User to JSON', () {
      // TODO: Add test after build_runner generates code
    });
  });
}

