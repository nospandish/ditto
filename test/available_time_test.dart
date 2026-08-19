import 'package:ditto/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> openAvailableTimeEditor(WidgetTester tester) async {
    await tester.pumpWidget(const DittoApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add available time'));
    await tester.pumpAndSettle();
  }

  Future<void> saveTimeBlock(WidgetTester tester) async {
    final saveButton = find.byKey(const Key('save-time-block-button'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
  }

  testWidgets('adds, edits, and deletes an available-time window', (
    tester,
  ) async {
    await openAvailableTimeEditor(tester);

    expect(find.text('Add Available Time'), findsOneWidget);
    expect(find.text('9:00 AM'), findsOneWidget);
    expect(find.text('12:00 PM'), findsOneWidget);
    await saveTimeBlock(tester);

    expect(find.text('9:00 AM – 12:00 PM'), findsOneWidget);
    expect(find.text('3h'), findsNWidgets(2));

    await tester.tap(find.byKey(const ValueKey('edit-time-block-0')));
    await tester.pumpAndSettle();
    expect(find.text('Edit Available Time'), findsOneWidget);

    final increaseStart = find.byKey(const Key('increase-start-time'));
    for (var i = 0; i < 4; i++) {
      tester.widget<IconButton>(increaseStart).onPressed!();
      await tester.pump();
    }
    await saveTimeBlock(tester);

    expect(find.text('10:00 AM – 12:00 PM'), findsOneWidget);
    expect(find.text('2h'), findsNWidgets(2));

    await tester.tap(find.byKey(const ValueKey('delete-time-block-0')));
    await tester.pumpAndSettle();
    expect(find.text('Delete available time?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('When are you free?'), findsOneWidget);
  });

  testWidgets('requires the end time to be later than the start time', (
    tester,
  ) async {
    await openAvailableTimeEditor(tester);

    final increaseStart = find.byKey(const Key('increase-start-time'));
    for (var i = 0; i < 12; i++) {
      tester.widget<IconButton>(increaseStart).onPressed!();
      await tester.pump();
    }
    final saveButton = find.byKey(const Key('save-time-block-button'));
    tester.widget<FilledButton>(saveButton).onPressed!();
    await tester.pumpAndSettle();

    expect(
      find.text('End time must be later than start time.'),
      findsOneWidget,
    );
    expect(find.text('Add Available Time'), findsOneWidget);
  });

  testWidgets('prevents overlapping available-time windows', (tester) async {
    await openAvailableTimeEditor(tester);
    await saveTimeBlock(tester);

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await saveTimeBlock(tester);

    expect(
      find.text('This time overlaps an existing available-time window.'),
      findsOneWidget,
    );
    expect(find.text('Add Available Time'), findsOneWidget);
  });
}
