import 'dart:math' as math;

import 'package:ditto/models/available_time_block.dart';
import 'package:ditto/widgets/available_time_clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps a full day clockwise around the dial', () {
    expect(availableTimeAngleForMinutes(0), closeTo(-math.pi / 2, 0.0001));
    expect(availableTimeAngleForMinutes(6 * 60), closeTo(0, 0.0001));
    expect(availableTimeAngleForMinutes(12 * 60), closeTo(math.pi / 2, 0.0001));
    expect(availableTimeAngleForMinutes(18 * 60), closeTo(math.pi, 0.0001));
  });

  testWidgets('summarizes multiple available-time windows', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AvailableTimeClock(
            blocks: [
              AvailableTimeBlock(startMinutes: 9 * 60, endMinutes: 12 * 60),
              AvailableTimeBlock(
                startMinutes: 13 * 60 + 30,
                endMinutes: 15 * 60,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('available-time-clock')), findsOneWidget);
    expect(find.text('4h 30m'), findsOneWidget);
    expect(find.text('12 AM'), findsOneWidget);
    expect(find.text('6 AM'), findsOneWidget);
    expect(find.text('12 PM'), findsOneWidget);
    expect(find.text('6 PM'), findsOneWidget);
    expect(find.text('Available'), findsOneWidget);
    expect(find.text('Unavailable'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Available time clock. 4h 30m available today. '
        'Available from 9:00 AM to 12:00 PM. '
        'Available from 1:30 PM to 3:00 PM.',
      ),
      findsOneWidget,
    );

    semantics.dispose();
  });
}
