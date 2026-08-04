import 'package:ditto/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the initial Today screen and primary navigation', (
    tester,
  ) async {
    await tester.pumpWidget(const DittoApp());

    expect(find.text('Today'), findsNWidgets(2));
    expect(find.text('Make today manageable.'), findsOneWidget);
    expect(find.text('Add your first task'), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Time'), findsOneWidget);
  });

  testWidgets('switches between primary screens', (tester) async {
    await tester.pumpWidget(const DittoApp());

    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();
    expect(find.text('No tasks yet'), findsOneWidget);

    await tester.tap(find.text('Time'));
    await tester.pumpAndSettle();
    expect(find.text('Available Time'), findsOneWidget);
    expect(find.text('When are you free?'), findsOneWidget);
  });
}
