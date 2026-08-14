import 'package:flutter_test/flutter_test.dart';
import 'package:passcoder/app/app.dart';

void main() {
  testWidgets('App should render', (WidgetTester tester) async {
    await tester.pumpWidget(const PassCoderApp());
    expect(find.text('PassCoder'), findsOneWidget);
  });
}
