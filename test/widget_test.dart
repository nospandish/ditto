import 'package:ditto/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the initial Today screen', (tester) async {
    await tester.pumpWidget(const DittoApp());

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Make today manageable.'), findsOneWidget);
    expect(find.text('Add your first task'), findsOneWidget);
  });
}
