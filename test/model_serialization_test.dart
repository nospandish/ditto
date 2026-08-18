import 'dart:convert';

import 'package:ditto/models/available_time_block.dart';
import 'package:ditto/models/ditto_task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DittoTask JSON serialization', () {
    for (final importance in TaskImportance.values) {
      test('round-trips ${importance.name} tasks with a due date', () {
        final original = DittoTask(
          name: 'Finish science project',
          dueDate: DateTime(2026, 8, 20, 17, 30),
          minimumMinutes: 45,
          maximumMinutes: 90,
          importance: importance,
        );

        final decodedJson = jsonDecode(jsonEncode(original.toJson()));
        final restored = DittoTask.fromJson(
          decodedJson as Map<String, dynamic>,
        );

        expect(restored.name, original.name);
        expect(restored.dueDate, original.dueDate);
        expect(restored.minimumMinutes, original.minimumMinutes);
        expect(restored.maximumMinutes, original.maximumMinutes);
        expect(restored.importance, original.importance);
      });
    }

    test('round-trips a task without a due date', () {
      const original = DittoTask(
        name: 'Organize desk',
        minimumMinutes: 15,
        maximumMinutes: 30,
        importance: TaskImportance.optional,
      );

      final decodedJson = jsonDecode(jsonEncode(original.toJson()));
      final restored = DittoTask.fromJson(decodedJson as Map<String, dynamic>);

      expect(restored.name, original.name);
      expect(restored.dueDate, isNull);
      expect(restored.minimumMinutes, original.minimumMinutes);
      expect(restored.maximumMinutes, original.maximumMinutes);
      expect(restored.importance, original.importance);
    });
  });

  test('AvailableTimeBlock round-trips through JSON', () {
    const original = AvailableTimeBlock(
      startMinutes: 9 * 60 + 15,
      endMinutes: 12 * 60 + 45,
    );

    final decodedJson = jsonDecode(jsonEncode(original.toJson()));
    final restored = AvailableTimeBlock.fromJson(
      decodedJson as Map<String, dynamic>,
    );

    expect(restored.startMinutes, original.startMinutes);
    expect(restored.endMinutes, original.endMinutes);
    expect(restored.durationMinutes, original.durationMinutes);
  });
}
