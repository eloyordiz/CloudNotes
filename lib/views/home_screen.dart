import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/database_service.dart';
import '../views/note_screen.dart';
import '../views/category_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<Note> notes;
  bool isLoading = false;

  Note? _selectedNote; // VARIABLE DE NOTA SELECCIONADA

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
      backgroundColor: const Color(0xFFF5F7FA),

      /* DIVIDIMOS LA PANTALLA EN 3 COLUMNAS, DE IZQUIERDA A DERECHA:
      - MENÚ LATERAL: ANCHO FIJO, CONTINENE LOGO, ACCIONES Y SINCRONIZACIÓN
      - LISTVIEW DE NOTAS: ANCHO FIJO, CONTIENE LAS NOTAS
      - EDITOR DE NOTAS: ANCHO VARIABLE, CONTIENE EL MENÚ DE EDICIÓN
      */
      body: Row(
        children: [
          // MENÚ LATERAL
          Container(
            width: 250, // ANCHO FIJO
            color: const Color(0xFFE3F2FD),
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  'LOGO DE LA APP',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.note_alt),
                  title: const Text('Todas mis notas'),
                  selected: true,
                  onTap: () {},
                ),

                // FALTA:
                //  CATEGORÍAS
                //  NOTAS ARCHIVADAS
                //  SINCRONIZACIÓN
              ],
            ),
          ),

          // LISTA DE NOTAS
          Container(
            width: 350, // ANCHO FIJO
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(
                  color: Colors.grey.shade300,
                ), // LÍNEA DE SEPARACIÓN
                left: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Column(
              children: [
                // CABECERA: BOTÓN Y BUSCADOR
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedNote =
                                null; // AL CREAR NOTA, BORRAMOS LA SELECCIONADA
                          });
                          // ACCIÓN PARA CREAR NUEVA NOTA
                        },
                        child: const Text('Nueva nota (+)'),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: TextField(
                          // BUSCADOR
                          decoration: InputDecoration(
                            hintText: 'Buscar',
                            prefixIcon: Icon(Icons.search, size: 20),
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        ) //INDICADOR DE PROGRESO
                      : notes.isEmpty
                      ? const Center(
                          child: Text(
                            "No hay ninguna nota guardada. Pulse 'Nueva nota' para crear una.",
                          ),
                        )
                      : ListView.builder(
                          //LISTVIEW DE NOTAS
                          itemCount: notes.length,
                          itemBuilder: (context, index) {
                            final note = notes[index];
                            final isSelected = _selectedNote?.id == note.id;

                            // DE MOMENTO MANTENEMOS EL DISMISSIBLE, AUNQUE LA ANIMACIÓN
                            // DE DESLIZAR PARA BORRAR NO SE VISUALZIA DEL TODO BIEN

                            return Dismissible(
                              //DISMISSIBLE PERMITE DESLIZAR PARA BORRAR
                              key: Key(note.id.toString()), // KEY PRINCIPAL

                              direction: DismissDirection
                                  .endToStart, // ENDTOSTART = DE DERECHA A IZQUIERDA

                              background: Container(
                                // PROPIEDADES VISUALES DE LA ACCIÓN DE DESLIZAR
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),

                              onDismissed: (direction) async {
                                // ACCIÓN AL DESLIZAR
                                // 1. BORRAR DE LA BD
                                await DatabaseService.instance.deleteNote(
                                  note.id!,
                                );
                                // 2. REFRESCAR
                                refreshNotes();
                                // 3. SNACKBAR INFORMATIVO
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Nota eliminada'),
                                  ),
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
                                    setState(() {
                                      _selectedNote = note;
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          //PANTALLE DE EDICIÓN
          Expanded(
            child: Container(
              color: Colors.white,
              child: _selectedNote == null
                  ? const Center(
                      child: Text(
                        'Selecciona una nota o crea una nueva para empezar',
                        style: TextStyle(color: Colors.grey, fontSize: 18),
                      ),
                    )
                  : Center(
                      // CONTENIDO DE LA PANTALLA NOTE_SCREEN
                      child: Text(
                        'Editor de la nota: ${_selectedNote!.title}',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
