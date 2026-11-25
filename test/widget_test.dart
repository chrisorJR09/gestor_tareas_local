import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/app_database.dart';
import 'package:gestor_tareas_local/screens/tareas_page.dart';

void main() {
  testWidgets('abre la pantalla principal', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());

    await tester.runAsync(() async {
      await tester.pumpWidget(MaterialApp(home: TareasPage(database: db)));
      // Deja que el stream de Drift emita la primera lista (vacía)
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await tester.pump();
    });

    expect(find.text('Gestor de tareas'), findsOneWidget);
    expect(find.text('Todavía no hay tareas guardadas'), findsOneWidget);

    // Desmontamos la pantalla para cancelar la suscripción y cerramos la base
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => db.close());
  });
}