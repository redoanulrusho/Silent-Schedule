import 'package:flutter_test/flutter_test.dart';
import 'package:silent_issue/main.dart';

void main() {
  testWidgets('App launches without error', (WidgetTester tester) async {
    await tester.pumpWidget(const SilentScheduleApp());
    await tester.pump();

    // The home screen should render the app title
    expect(find.text('Silent Schedule'), findsOneWidget);
  });
}
