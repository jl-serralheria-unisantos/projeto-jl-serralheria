import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_jl_serralheria/app.dart';

void main() {
  testWidgets('App inicia com tela inicial', (WidgetTester tester) async {
    await tester.pumpWidget(const SerralheriaApp());

    expect(find.text('JL Serralheria'), findsOneWidget);
    expect(find.text('Clientes'), findsOneWidget);
    expect(find.text('Produtos'), findsOneWidget);
    expect(find.text('Serviços'), findsOneWidget);
    expect(find.text('Orçamentos'), findsOneWidget);
  });
}