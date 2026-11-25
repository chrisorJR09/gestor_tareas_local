import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/app_database.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  // Validación de entradas (F1, P5)
  test('rechaza títulos vacíos o de solo espacios', () {
    expect(() => db.agregar(''), throwsArgumentError);
    expect(() => db.agregar('   '), throwsArgumentError);
  });

  // Operación de almacenamiento (F1, F2)
  test('guarda una tarea y la devuelve en la consulta', () async {
    await db.agregar('Estudiar');
    final lista = await db.observarTareas().first;
    expect(lista.length, 1);
    expect(lista.first.titulo, 'Estudiar');
    expect(lista.first.completada, isFalse);
  });
}