import 'package:flutter/material.dart';
import '../models/note.dart';
import '../models/note_category.dart';
import '../services/database_service.dart';
import '../views/note_screen.dart';
import '../views/category_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<Note> notes = [];
  late List<NoteCategory> categories = [];
  bool isLoading = false;

  // VARIABLE DE NOTA SELECCIONADA
  Note? _selectedNote;

  // VARIABLE PARA SABER SI ESTAMOS CREANDO O EDITANDO
  bool _isCreating = false;

  // VARIABLES DE LAS PROPIEDADES DE LA NOTA: COLOR, ARCHIVADO Y CATEGORÍA
  int _selectedColor = 0xFFFFFFFF; // Blanco por defecto
  bool _isArchived = false;
  int? _selectedCategoryId;

  // VARIABLE DEL CONTENIDO DEL BUSCADOR
  String _searchQuery = '';

  // VARIABLE PARA FILTRAR O NO POR ARCHIVADAS
  bool _showArchivedOnly = false;

  // VARIABLE PARA FILTRAR POR CATEGORÍA CONCRETA
  int? _activeCategoryFilter;

  // COLORES POSIBLES
  final List<int> _colors = [
    0xFFFFFFFF, // Blanco
    0xFFFF8A80, // Rojo pastel
    0xFFFFD180, // Naranja pastel
    0xFFFFFF8D, // Amarillo pastel
    0xFFCCFF90, // Verde pastel
    0xFF80D8FF, // Azul pastel
    0xFFEA80FC, // Morado pastel
  ];

  // CONTROLADORES DE EDITOR DE TEXTO PARA:
  //TÍTULO
  final TextEditingController _titleController = TextEditingController();
  //CONTENIDO
  final TextEditingController _contentController = TextEditingController();
  //BUSCADOR
  final TextEditingController _searchController = TextEditingController();

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
    categories = await DatabaseService.instance.readAllCategories();

    setState(() => isLoading = false);
  }

  // FUNCIÓN PARA GUARDAR UNA NOTA, DEPENDIENDO DE SI CREAS O EDITAR
  Future<void> _saveCurrentNote() async {
    if (_titleController.text.isEmpty && _contentController.text.isEmpty)
      return;

    if (_selectedNote != null) {
      // ACTUALIZAR NOTA
      final updatedNote = Note(
        id: _selectedNote!.id,
        categoryId: _selectedCategoryId,
        title: _titleController.text.isEmpty
            ? 'Sin título'
            : _titleController.text,
        content: _contentController.text,
        color: _selectedColor,
        createdAt: _selectedNote!.createdAt,
        updatedAt: DateTime.now(),
        isArchived: _isArchived,
        isSynced: false,
      );
      await DatabaseService.instance.updateNote(updatedNote);
    } else {
      // CREAR NOTA NUEVA
      final newNote = Note(
        categoryId: _selectedCategoryId,
        title: _titleController.text.isEmpty
            ? 'Sin título'
            : _titleController.text,
        content: _contentController.text,
        color: _selectedColor,
        createdAt: DateTime.now(),
        isArchived: _isArchived,
        isSynced: false,
      );
      await DatabaseService.instance.createNote(newNote);
      setState(() => _isCreating = false); // Salimos del modo creación
    }

    refreshNotes(); // Refrescamos la lista central
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nota guardada correctamente')),
    );
  }

  @override
  Widget build(BuildContext context) {
    //USAMOS FILTEREDNOTES PARA FILTRAR EN CASO DE QUE HAYA ALGO EN EL BUSCADOR
    final filteredNotes = notes.where((note) {
      //ARCHIVADO
      if (note.isArchived != _showArchivedOnly) return false;

      //CATEGORÍA
      if (_activeCategoryFilter != null &&
          note.categoryId != _activeCategoryFilter)
        return false;

      //BUSCADOR
      final query = _searchQuery.toLowerCase();
      final titleMatch = note.title.toLowerCase().contains(query);
      final contentMatch = note.content.toLowerCase().contains(query);
      return titleMatch || contentMatch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      /* DIVIDIMOS LA PANTALLA EN 3 COLUMNAS, DE IZQUIERDA A DERECHA:
      - MENÚ LATERAL: ANCHO FIJO, CONTINENE LOGO, ACCIONES Y SINCRONIZACIÓN
      - LISTVIEW DE NOTAS: ANCHO FIJO, CONTIENE LAS NOTAS
      - EDITOR DE NOTAS: ANCHO VARIABLE, CONTIENE EL MENÚ DE EDICIÓN
      */
      body: Row(
        children: [
          /* MENÚ LATERAL. LO DIVIDIMOS EN:
          - LOGO DE LA APP
          - SECCIÓN SUPERIOR: TODAS LAS NOTAS, CATEGORÍAS, Y ARCHIVADAS
          - SINCRONIZACIÓN
          - USUARIO
          */
          Container(
            width: 250, // ANCHO FIJO
            color: const Color(0xFFE3F2FD),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // LOGO DE LA APP
                const Text(
                  'LOGO DE LA APP',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // SECCIÓN SUPERIOR
                // TODAS LAS NOTAS
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.note_alt, color: Colors.blue),
                        title: Text(
                          'Todas mis notas',
                          style: TextStyle(
                            fontWeight: _showArchivedOnly
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                        selected: !_showArchivedOnly,
                        selectedTileColor: Colors.blue.shade50,
                        onTap: () {
                          setState(() {
                            _showArchivedOnly = false;
                            _activeCategoryFilter = null;
                            _selectedNote = null;
                          });
                        },
                      ),

                      // CATEGORÍAS
                      ExpansionTile(
                        leading: const Icon(Icons.folder_outlined),
                        title: const Text('Categorías'),
                        childrenPadding: const EdgeInsets.only(left: 16),
                        children: [
                          ...categories.map((category) {
                            final isSelected =
                                _activeCategoryFilter == category.id;

                            return ListTile(
                              leading: Icon(
                                Icons.label_important_outline,
                                size: 18,
                                color: isSelected ? Colors.blue : Colors.grey,
                              ),
                              title: Text(
                                category.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              selected: isSelected,
                              selectedTileColor: Colors.blue.shade50,
                              onTap: () {
                                setState(() {
                                  _activeCategoryFilter = category.id;
                                  _showArchivedOnly = false;
                                  _selectedNote = null;
                                });
                              },
                            );
                          }).toList(),
                          ListTile(
                            leading: const Icon(
                              Icons.settings_suggest,
                              size: 20,
                            ),
                            title: const Text(
                              'Editar categorías',
                              style: TextStyle(fontSize: 14),
                            ),
                            onTap: () async {
                              //NAVEGAMOS ESPERANDO EL RESULTADO, QUE SERÁ SI VOLVEMOS
                              //MARCANDO ARCHIVADAS (TRUE) O TODAS MIS NOTAS (FALSE)
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CategoryScreen(),
                                ),
                              );

                              if (result != null) {
                                setState(() {
                                  //RESULT = TRUE: ARCHIVADADS
                                  if (result == true) {
                                    _showArchivedOnly = true;
                                    _activeCategoryFilter = null;
                                    _selectedNote = null;
                                    //RESULT = FALSE: TODAS
                                  } else if (result == false) {
                                    _showArchivedOnly = false;
                                    _activeCategoryFilter = null;
                                    _selectedNote = null;
                                  }
                                });
                              }
                              refreshNotes();
                            },
                          ),
                        ],
                      ),

                      // ARCHIVADAS
                      ListTile(
                        leading: const Icon(Icons.archive_outlined),
                        title: Text(
                          'Archivadas',
                          style: TextStyle(
                            fontWeight: _showArchivedOnly
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        selected: _showArchivedOnly,
                        onTap: () {
                          setState(() {
                            _showArchivedOnly = true;
                            _activeCategoryFilter = null;
                            _selectedNote = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // SINCRONIZACIÓN
                // PENDIENTE:
                //   MOSTRAR CORRECTAMENTE EL ESTADO DE SINCRONIZACIÓN
                //   MOSTRAR CORRECTAMENTE LA HORA DE ÚLTIMA ACTUALIZACIÓN
                //   CONFIGURAR PARA QUE, AL HACER CLICK, SE FUERCE LA SINCRONIZACIÓN CON NUBE
                Container(
                  color: Colors.green.shade50,
                  child: ListTile(
                    leading: const Icon(Icons.cloud_done, color: Colors.green),
                    title: const Text(
                      'Sincronizado',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'Última sincronización: hace 4 min.',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                    onTap: () {},
                  ),
                ),

                const Divider(height: 1),

                // USUARIO
                ListTile(
                  leading: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.person, color: Colors.white, size: 18),
                  ),
                  title: const Text(
                    'Eloy Ordiz Lera',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: const Text(
                    'eloyordizl@gmail.com',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // LISTA DE NOTAS
          Container(
            width: 350, // ANCHO FIJO
            clipBehavior: Clip
                .hardEdge, //PERMITE QUE NO SE PONGA POR ENCIMA DEL MENÜ LATERAL
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
                            _selectedNote = null;
                            _isCreating =
                                true; // Forzamos a mostrar el panel vacío
                            _titleController.clear();
                            _contentController.clear();
                            _selectedColor = 0xFFFFFFFF; // Blanco por defecto
                            _isArchived = false;
                            _selectedCategoryId = null;
                          });
                        },
                        child: const Text('Nueva nota (+)'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Buscar',
                            prefixIcon: Icon(Icons.search, size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
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
                      : filteredNotes.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty
                                ? "No hay ninguna nota guardada. Pulse 'Nueva nota' para crear una."
                                : "No se encontraron notas con '$_searchQuery'.",
                          ),
                        )
                      : ListView.builder(
                          //LISTVIEW DE NOTAS
                          itemCount: filteredNotes.length,
                          itemBuilder: (context, index) {
                            final note = filteredNotes[index];
                            final isSelected = _selectedNote?.id == note.id;

                            //EL DISMISSIBLE NO TERMINA DE QUEDAR DEL TODO BIEN YA QUE APARECE EL BORDE BLANCO LATERAL MIENTRAS SE DESLIZA
                            //BUSCAR EN LA DOCUMENTACIÓN ALGUNA POSIBLE SOLUCIÓN, QUIZÁS PONER EL CARD POR FUERA Y EL DISMISSIBLE
                            //POR DENTRO PUEDE RESOLVER EL PROBLEMA
                            return Dismissible(
                              //DISMISSIBLE PERMITE DESLIZAR PARA BORRAR
                              key: Key(note.id.toString()), // KEY PRINCIPAL

                              direction: DismissDirection
                                  .endToStart, // ENDTOSTART = DE DERECHA A IZQUIERDA

                              background: Container(
                                // PROPIEDADES VISUALES DE LA ACCIÓN DE DESLIZAR
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade400,
                                  borderRadius: BorderRadius.circular(
                                    12,
                                  ), // Mismo borde que la Card
                                ),

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
                                color: Color(note.color),
                                elevation: isSelected ? 3 : 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isSelected
                                        ? Colors.blue
                                        : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: ListTile(
                                  // PROPIEDADES DE LA NOTA
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  title: Text(
                                    note.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ), //TÍTULO

                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      //CONTENIDO
                                      note.content,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedNote = note;
                                      _isCreating = false;
                                      _titleController.text = note.title;
                                      _contentController.text = note.content;
                                      _selectedColor = note.color;
                                      _isArchived = note.isArchived;
                                      _selectedCategoryId = note.categoryId;
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

          //APARTADO DE EDICIÓN
          Expanded(
            child: Container(
              color: _selectedNote == null && !_isCreating
                  ? Colors.white
                  : Color(_selectedColor),
              child: _selectedNote == null && !_isCreating
                  ? const Center(
                      child: Text(
                        'Selecciona una nota o crea una nueva para empezar',
                        style: TextStyle(color: Colors.grey, fontSize: 18),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // BARRA SUPERIOR DE ACCIONES: SINCRONIZACIÓN, GUARDAR, ARCHIVAR Y BORRAR
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              //SINCRONIZACIÓN
                              const Icon(
                                Icons.cloud_done,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Sincronizado',
                                style: TextStyle(color: Colors.green),
                              ),
                              const Spacer(),

                              //GUARDAR
                              TextButton.icon(
                                onPressed: _saveCurrentNote,
                                icon: const Icon(Icons.save_outlined),
                                label: const Text('Guardar'),
                              ),

                              //ARCHIVAR
                              TextButton.icon(
                                onPressed: () async {
                                  if (_selectedNote != null) {
                                    setState(() {
                                      _isArchived = !_isArchived;
                                    });
                                    await _saveCurrentNote();
                                    setState(() {
                                      _selectedNote = null;
                                    });
                                  }
                                },
                                icon: Icon(
                                  _isArchived
                                      ? Icons.unarchive
                                      : Icons.archive_outlined,
                                  color: _isArchived ? Colors.orange : null,
                                ),
                                label: Text(
                                  _isArchived ? 'Desarchivar' : 'Archivar',
                                  style: TextStyle(
                                    color: _isArchived ? Colors.orange : null,
                                  ),
                                ),
                              ),

                              //BORRAR
                              TextButton.icon(
                                onPressed: () async {
                                  await DatabaseService.instance.deleteNote(
                                    _selectedNote!.id!,
                                  );
                                  setState(() => _selectedNote = null);
                                  refreshNotes();
                                },
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                label: const Text(
                                  'Eliminar',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        // CUERPO DEL EDITOR: CONTENIDO DE NOTE_SCREEN,
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 20,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        TextField(
                                          controller: _titleController,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          decoration: const InputDecoration(
                                            hintText: 'Título',
                                            border: InputBorder.none,
                                          ),
                                        ),
                                        Expanded(
                                          child: TextField(
                                            controller: _contentController,
                                            maxLines: null,
                                            keyboardType:
                                                TextInputType.multiline,
                                            decoration: const InputDecoration(
                                              hintText: 'Empieza a escribir...',
                                              border: InputBorder.none,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // BARRA INFERIOR DE COLORES
                                Container(
                                  height: 60,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _colors.length,
                                    itemBuilder: (context, index) {
                                      final color = _colors[index];
                                      final isSelected =
                                          color == _selectedColor;
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedColor = color;
                                          });
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Color(color),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected
                                                  ? Colors.black54
                                                  : Colors.grey.shade300,
                                              width: isSelected ? 2 : 1,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ),

                        // 3. PIE DE PÁGINA
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              const Text(
                                'Categoría: ',
                                style: TextStyle(color: Colors.grey),
                              ),
                              //POPUP PARA SELECCIONAR CATEGORÍA
                              PopupMenuButton<int?>(
                                initialValue: _selectedCategoryId,
                                tooltip: 'Asignar categoría',
                                onSelected: (int? newId) {
                                  setState(() {
                                    _selectedCategoryId = newId;
                                  });
                                },
                                itemBuilder: (BuildContext context) {
                                  return [
                                    const PopupMenuItem<int?>(
                                      value: null,
                                      child: Text(
                                        'Sin categoría',
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                    ...categories.map((category) {
                                      return PopupMenuItem<int?>(
                                        value: category.id,
                                        child: Text(category.name),
                                      );
                                    }).toList(),
                                  ];
                                },
                                child: Chip(
                                  label: Text(
                                    _selectedCategoryId == null
                                        ? 'Sin categoría'
                                        : categories
                                              .firstWhere(
                                                (c) =>
                                                    c.id == _selectedCategoryId,
                                                orElse: () => NoteCategory(
                                                  id: -1,
                                                  name: 'Desconocida',
                                                  iconCodePoint: 0,
                                                  createdAt: DateTime.now(),
                                                ),
                                              )
                                              .name,
                                  ),
                                  avatar: const Icon(
                                    Icons.arrow_drop_down,
                                    size: 18,
                                  ),
                                  backgroundColor: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _selectedNote == null
                                    ? 'Nota nueva'
                                    : 'Última mod: ${_selectedNote!.updatedAt.day}/${_selectedNote!.updatedAt.month} a las ${_selectedNote!.updatedAt.hour}:${_selectedNote!.updatedAt.minute}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
