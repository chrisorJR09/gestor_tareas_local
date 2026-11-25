import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// DataClassName evita choque con tu modelo lib/models/tarea.dart
@DataClassName('TareaRow')
class Tareas extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get titulo => text().withLength(min: 1, max: 200)();
  BoolColumn get completada => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(tables: [Tareas])
class AppDatabase extends _$AppDatabase {
  // El parámetro opcional permite inyectar una BD en memoria para pruebas
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _abrir());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _abrir() => driftDatabase(
        name: 'gestor_tareas',
        web: DriftWebOptions(
          sqlite3Wasm: Uri.parse('sqlite3.wasm'),
          driftWorker: Uri.parse('drift_worker.js'),
        ),
      );

  // Consulta reactiva: la UI se actualiza sola tras cada escritura
  Stream<List<TareaRow>> observarTareas() =>
      (select(tareas)..orderBy([(t) => OrderingTerm.asc(t.id)])).watch();

  Future<int> agregar(String titulo) {
    final limpio = titulo.trim();
    if (limpio.isEmpty) throw ArgumentError('El título no puede estar vacío');
    return into(tareas).insert(TareasCompanion.insert(titulo: limpio));
  }

  Future<int> editarTitulo(int id, String titulo) {
    final limpio = titulo.trim();
    if (limpio.isEmpty) throw ArgumentError('El título no puede estar vacío');
    return (update(tareas)..where((t) => t.id.equals(id)))
        .write(TareasCompanion(titulo: Value(limpio)));
  }

  Future<int> cambiarEstado(int id, bool completada) =>
      (update(tareas)..where((t) => t.id.equals(id)))
          .write(TareasCompanion(completada: Value(completada)));

  Future<int> eliminar(int id) =>
      (delete(tareas)..where((t) => t.id.equals(id))).go();
}