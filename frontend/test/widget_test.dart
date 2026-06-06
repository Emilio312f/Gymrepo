import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gymcontrol_app/main.dart';

void main() {
  testWidgets('La app arranca en la pantalla de login', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: GymControlApp()));
    await tester.pump();

    expect(find.text('GymControl'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
