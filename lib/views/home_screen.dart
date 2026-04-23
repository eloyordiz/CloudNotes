import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/database_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<Note> notes;
  bool isLoading = false;

  // INICIALIZAMOS LA PRIMERA VEZ QUE ABRIMOS LA PANTALLA
  @override
  void initState() {
    super.initState();
    refreshNotes(); // LEEMOS TODAS LAS NOTAS DE LA BD
  }

  // FUNCIÓN PARA LEER LA BD
  Future refreshNotes() async {
    setState(() => isLoading = true); //CÍRUCLO DE CARGA

    notes = await DatabaseService.instance.readAllNotes();

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CloudNotes'),
        centerTitle: true,
        elevation: 2,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notes.isEmpty
          ? const Center(
              child: Text("ESTE TEXTO SE MUESTRA CUANDO NO HAY NOTAS"),
            )
          : ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.note_alt_outlined,
                      color: Colors.blue,
                    ),
                    title: Text(note.title),
                    subtitle: Text(note.content),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // CÓDIGO DE PRUEBA. GENERA UNA NOTA DE PRUEBA AL PULSAR EL BOTÓN
          final nuevaNota = Note(
            title: "Nota de prueba ${notes.length + 1}",
            content: "Esto se ha guardado en SQLite de verdad.",
            createdAt: DateTime.now(),
          );

          await DatabaseService.instance.createNote(nuevaNota);

          // REFRESCAMOS LA LISTA DESPUÉS DE CREAR
          refreshNotes();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
