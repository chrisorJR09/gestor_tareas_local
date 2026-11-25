import 'package:flutter/material.dart';
import '../data/app_database.dart';

class TareasPage extends StatefulWidget {
  // Si no se pasa una base, la página crea y administra la suya
  final AppDatabase? database;
  const TareasPage({super.key, this.database});

  @override
  State<TareasPage> createState() => _TareasPageState();
}

class _TareasPageState extends State<TareasPage> {
  final TextEditingController _tituloController = TextEditingController();
  late final AppDatabase _db;
  late final Stream<List<TareaRow>> _tareas;
  late final bool _creeLaBase;

  @override
  void initState() {
    super.initState();
    _creeLaBase = widget.database == null;
    _db = widget.database ?? AppDatabase();
    // El stream se crea una sola vez: no se consulta la BD dentro de build()
    _tareas = _db.observarTareas();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    // Solo cerramos la base si la creó esta página
    if (_creeLaBase) _db.close();
    super.dispose();
  }

  /// Ejecuta una operación de base de datos y devuelve true si salió bien.
  Future<bool> _ejecutar(Future<Object?> Function() accion) async {
    try {
      await accion();
      return true;
    } on ArgumentError {
      _mostrarMensaje('El título no puede estar vacío.');
    } catch (e) {
      _mostrarMensaje('No se pudo completar la operación. Intenta de nuevo.');
      debugPrint('Error de almacenamiento: $e');
    }
    return false;
  }

  void _mostrarMensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _agregarTarea() async {
    final titulo = _tituloController.text;
    if (titulo.trim().isEmpty) {
      _mostrarMensaje('El título no puede estar vacío.');
      return;
    }
    final guardado = await _ejecutar(() => _db.agregar(titulo));
    // Si falló el guardado, se conserva el texto para que el usuario reintente
    if (guardado) _tituloController.clear();
  }

  Future<void> _alternarCompletada(TareaRow tarea, bool completada) =>
      _ejecutar(() => _db.cambiarEstado(tarea.id, completada));

  Future<void> _eliminarTarea(TareaRow tarea) =>
      _ejecutar(() => _db.eliminar(tarea.id));

  Future<void> _editarTarea(TareaRow tarea) async {
    final nuevo = await showDialog<String>(
      context: context,
      builder: (_) => _DialogoEditar(tituloInicial: tarea.titulo),
    );
    if (nuevo == null) return; // canceló
    await _ejecutar(() => _db.editarTitulo(tarea.id, nuevo));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestor de tareas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _tituloController,
              decoration: const InputDecoration(
                labelText: 'Nueva tarea',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _agregarTarea(),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _agregarTarea,
              icon: const Icon(Icons.add),
              label: const Text('Agregar tarea'),
            ),
            const SizedBox(height: 12),
            const Text('Mis tareas', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<TareaRow>>(
                stream: _tareas,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Error al leer las tareas guardadas'),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final tareas = snapshot.data!;
                  if (tareas.isEmpty) {
                    return const Center(
                      child: Text('Todavía no hay tareas guardadas'),
                    );
                  }
                  return ListView.builder(
                    itemCount: tareas.length,
                    itemBuilder: (context, index) {
                      final tarea = tareas[index];
                      return Card(
                        child: ListTile(
                          leading: Checkbox(
                            value: tarea.completada,
                            onChanged: (valor) {
                              if (valor != null) {
                                _alternarCompletada(tarea, valor);
                              }
                            },
                          ),
                          title: Text(
                            tarea.titulo,
                            style: tarea.completada
                                ? const TextStyle(
                                    decoration: TextDecoration.lineThrough)
                                : null,
                          ),
                          subtitle: Text('ID: ${tarea.id}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Editar',
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editarTarea(tarea),
                              ),
                              IconButton(
                                tooltip: 'Eliminar',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _eliminarTarea(tarea),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// El controller vive en su propio State para liberarse con el diálogo
class _DialogoEditar extends StatefulWidget {
  final String tituloInicial;
  const _DialogoEditar({required this.tituloInicial});

  @override
  State<_DialogoEditar> createState() => _DialogoEditarState();
}

class _DialogoEditarState extends State<_DialogoEditar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.tituloInicial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar tarea'),
      content: TextField(controller: _controller, autofocus: true),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}