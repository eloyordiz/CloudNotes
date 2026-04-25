import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/database_service.dart';
import '../views/note_screen.dart';

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
        title: const Text('CloudNotes'), //TÍTULO
        centerTitle: true, //CENTRADO
        elevation: 2, //ELEVACIÓN
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            ) //INDICADOR DE PROGRESO
          : notes.isEmpty
          ? const Center(
              child: Text("ESTE TEXTO SE MUESTRA CUANDO NO HAY NOTAS"),
            )
          : ListView.builder(
              //LISTVIEW DE NOTAS
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return Dismissible(
                  //DISMISSIBLE PERMITE DESLIZAR PARA BORRAR
                  key: Key(note.id.toString()), // KEY PRINCIPAL

                  direction: DismissDirection
                      .endToStart, // ENDTOSTART = DE DERECHA A IZQUIERDA

                  background: Container(
                    // PROPIEDADES VISUALES DE LA ACCIÓN DE DESLIZAR
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),

                  onDismissed: (direction) async {
                    // ACCIÓN AL DESLIZAR
                    // 1. BORRAR DE LA BD
                    await DatabaseService.instance.deleteNote(note.id!);
                    // 2. REFRESCAR
                    refreshNotes();
                    // 3. SNACKBAR INFORMATIVO
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nota eliminada')),
                    );
                  },

                  child: Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 8,
                    ),

                    child: ListTile(
                      // PROPIEDADES DE LA NOTA
                      leading: const Icon(
                        //ICONO
                        Icons.note_alt_outlined,
                        color: Colors.blue,
                      ),

                      title: Text(note.title), //TÍTULO

                      subtitle: Text(
                        //CONTENIDO
                        note.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                      ), //CHEVRON

                      onTap: () async {
                        //ACCIÓN AL PULSAR
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NoteScreen(
                              note: note,
                            ), //NAVEGAMOS A LA PANTALLA DE EDICIÓN
                          ),
                        );

                        if (result == true) {
                          // SI LO QUE SE DEVUELVE ES TRUE (LA NOTA SE HA CREADO O EDITADO),
                          refreshNotes(); // SE REFRESCA LA PANTALLA
                        }
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        //BOTÓN DE NUEVA NOTA
        onPressed: () async {
          // NAVEGAMOS A PANTALLA DE EDICIÓN
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NoteScreen()),
          );

          // SI EL RESULTADO ES TRUE, REFRESCAMOS
          if (result == true) {
            refreshNotes();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
