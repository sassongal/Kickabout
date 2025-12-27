import 'package:flutter_test/flutter_test.dart';
import 'package:kattrick/shared/domain/models/enums/game_status.dart';

void main() {
  group('Game Model', () {
    test('should create Game from JSON', () {
      // TODO: Add test after build_runner generates code
    });

    test('should convert Game to JSON', () {
      // TODO: Add test after build_runner generates code
    });

    test('GameStatus enum should work', () {
      expect(GameStatus.teamSelection.toFirestore(), 'teamSelection');
      expect(GameStatus.fromFirestore('inProgress'), GameStatus.inProgress);
    });
  });
}
