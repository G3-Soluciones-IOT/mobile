import 'package:flutter_test/flutter_test.dart';
import 'package:jameofit/app/app.dart';

void main() {
  testWidgets('renders IoT dashboard shell', (tester) async {
    await tester.pumpWidget(const JameoFitApp());
    await tester.pumpAndSettle();

    expect(find.text('Smart Tracking'), findsOneWidget);
    expect(find.text('Bebedor Inteligente'), findsWidgets);
    expect(find.text('Coach IA'), findsOneWidget);
  });
}
