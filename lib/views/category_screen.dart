import 'package:flutter/material.dart';
import '../models/note_category.dart';
import '../services/database_service.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<NoteCategory> categories = [];
  Map<int, int> categoryNoteCounts =
      {}; //DICCIONARIO DE RECUENTO DE NOTAS POR CATEGORÍA
  bool isLoading = false;

  // VARIABLES DEL BUSCADOR
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // LISTA DE ICONOS POSIBLES PARA ELEGIR (AMPLIAR)
  final List<IconData> _availableIcons = [
    Icons.folder,
    Icons.work,
    Icons.home,
    Icons.shopping_cart,
    Icons.school,
    Icons.favorite,
    Icons.star,
    Icons.lightbulb,
    Icons.flight,
    Icons.directions_car,
    Icons.fitness_center,
    Icons.restaurant,
    Icons.account_balance,
    Icons.pets,
    Icons.music_note,
    Icons.camera_alt,
  ];

  // INICIALIZAMOS LA PRIMERA VEZ QUE ABRIMOS LA PANTALLA
  @override
  void initState() {
    super.initState();
    refreshCategories(); // LEEMOS TODAS LAS CATEGORÍAS DE LA BD
  }

  // FUNCIÓN PARA LEER LA BD
  Future refreshCategories() async {
    setState(() => isLoading = true); // CÍRCULO DE CARGA

    categories = await DatabaseService.instance.readAllCategories();
    //RECUENTO DE NOTAS POR CATEGORÍA
    categoryNoteCounts.clear();
    for (var category in categories) {
      if (category.id != null) {
        final count = await DatabaseService.instance.countNotesInCategory(
          category.id!,
        );
        categoryNoteCounts[category.id!] = count;
      }
    }

    setState(() => isLoading = false);
  }

  // POPUP PARA CREAR O EDITAR UNA CATEGORÍA
  Future<void> _showCategoryDialog({NoteCategory? categoryToEdit}) async {
    // VARIABLE PARA SABER SI ESTAMOS EDITANDO O CREANDO
    final isEditing = categoryToEdit != null;

    // CONTROLADOR DEL TEXTO CON EL NOMBRE ACTUAL SI ESTAMOS EDITANDO
    final nameController = TextEditingController(
      text: isEditing ? categoryToEdit.name : '',
    );

    // ICONO POR DEFECTO (CARPETA) O EL QUE YA TENÍA LA CATEGORÍA
    int selectedIconCode = isEditing
        ? (categoryToEdit.iconCodePoint ?? Icons.folder.codePoint)
        : Icons.folder.codePoint;

    await showDialog(
      context: context,
      builder: (context) {
        // STATEFULBUILDER PERMITE ACTUALIZAR EL ESTADO SOLO DENTRO DEL POPUP (EJ: AL CAMBIAR DE ICONO)
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEditing ? 'Editar Categoría' : 'Nueva Categoría'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NOMBRE DE LA CATEGORÍA
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la categoría',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Selecciona un icono:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    // ICONOS
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _availableIcons.map((icon) {
                        final isSelected = selectedIconCode == icon.codePoint;

                        return InkWell(
                          onTap: () {
                            setStateDialog(() {
                              selectedIconCode = icon.codePoint;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blue.shade50
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blue
                                    : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Icon(
                              icon,
                              color: isSelected
                                  ? Colors.blue
                                  : Colors.grey.shade700,
                              size: 28,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                // BOTÓN CANCELAR
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                // BOTÓN GUARDAR / ACTUALZIZAR
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty)
                      return; // EVITAMOS CATEGORÍAS SIN NOMBRE

                    if (isEditing) {
                      // ACTUALIZAR CATEGORÍA EN LA BD
                      final updatedCategory = NoteCategory(
                        id: categoryToEdit.id,
                        name: nameController.text,
                        iconCodePoint: selectedIconCode,
                        createdAt: categoryToEdit.createdAt,
                        isSynced: categoryToEdit.isSynced,
                      );
                      await DatabaseService.instance.updateCategory(
                        updatedCategory,
                      );
                    } else {
                      // CREAR NUEVA CATEGORÍA EN LA BD
                      final newCategory = NoteCategory(
                        name: nameController.text,
                        iconCodePoint: selectedIconCode,
                        createdAt: DateTime.now(),
                      );
                      await DatabaseService.instance.createCategory(
                        newCategory,
                      );
                    }

                    if (context.mounted) Navigator.pop(context);
                    refreshCategories();
                  },
                  child: Text(isEditing ? 'Actualizar' : 'Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // FILTRO DEL BUSCADOR
    final filteredCategories = categories.where((cat) {
      return cat.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      /* DIVIDIMOS LA PANTALLA EN 2 COLUMNAS, DE IZQUIERDA A DERECHA:
      - MENÚ LATERAL: ANCHO FIJO, CONTINENE LOGO Y NAVEGACIÓN
      - GESTIÓN DE CATEGORÍAS: ANCHO VARIABLE, CONTIENE LAS CATEGORÍAS , ACCIONES Y BUSCADOR
      */
      body: Row(
        children: [
          // 1. MENÚ LATERAL
          Container(
            width: 250,
            color: const Color(0xFFE3F2FD),
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  'LOGO DE LA APP',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // SECCIÓN SUPERIOR
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // TODAS LAS NOTAS
                      ListTile(
                        leading: const Icon(Icons.note_alt, color: Colors.grey),
                        title: const Text('Todas mis notas'),
                        onTap: () {
                          Navigator.pop(
                            context,
                            false,
                          ); //PARÁMETRO = VER ARCHIVADAS ?
                        },
                      ),

                      // CATEGORÍAS
                      ListTile(
                        leading: const Icon(Icons.folder, color: Colors.blue),
                        title: const Text(
                          'Categorías',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        selected: true,
                        selectedTileColor: Colors.blue.shade50,
                        onTap: () {},
                      ),

                      // ARCHIVADAS
                      ListTile(
                        leading: const Icon(
                          Icons.archive_outlined,
                          color: Colors.grey,
                        ),
                        title: const Text('Archivadas'),
                        onTap: () {
                          Navigator.pop(
                            context,
                            true, //PARÁMETRO = VER ARCHIVADAS ?
                          );
                        },
                      ),
                    ],
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

          // 2. GESTIÓN DE CATEGORÍAS
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PARTE SUPERIOR: TÍTULO, BUSCADOR Y BOTÓN CREAR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      //TÍTULO
                      const Text(
                        'Gestión de Categorías',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      //BUSCADOR
                      Row(
                        children: [
                          // BUSCADOR DE CATEGORÍAS
                          SizedBox(
                            width: 250,
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) =>
                                  setState(() => _searchQuery = val),
                              decoration: InputDecoration(
                                hintText: 'Buscar',
                                prefixIcon: const Icon(Icons.search, size: 20),
                                filled: true,
                                fillColor: Colors.white,
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          //BOTÓN NUEVA CATEGORÍA
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => _showCategoryDialog(),
                            child: const Text('Crear Nueva Categoría (+)'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Todas las Categorías',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 20),

                  // CATEGORÍAS
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : filteredCategories.isEmpty
                        ? const Center(
                            child: Text('No se encontraron categorías.'),
                          )
                        : GridView.builder(
                            // MAX CROSS AXIS EXTENT PERMITE QUE EL NÚMERO DE COLUMNAS SE ADAPTE AL ANCHO DE LA PANTALLA
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 350,
                                  mainAxisExtent: 140,
                                  crossAxisSpacing: 20,
                                  mainAxisSpacing: 20,
                                ),
                            itemCount: filteredCategories.length,
                            itemBuilder: (context, index) {
                              final category = filteredCategories[index];
                              final noteCount =
                                  categoryNoteCounts[category.id] ?? 0;

                              return Card(
                                color: Colors.white,
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey.shade200),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // ICONO Y NOMBRE
                                      Row(
                                        children: [
                                          // ICONO (USAMOS AVATAR PARA VERLO MEJOR)
                                          CircleAvatar(
                                            radius: 24,
                                            backgroundColor:
                                                Colors.blue.shade50,
                                            child: Icon(
                                              IconData(
                                                category.iconCodePoint ??
                                                    Icons.folder.codePoint,
                                                fontFamily: 'MaterialIcons',
                                              ),
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  category.name,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  '$noteCount notas',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      // ACCIONES EDITAR Y ELIMINAR
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          // BOTÓN EDITAR
                                          OutlinedButton.icon(
                                            onPressed: () =>
                                                _showCategoryDialog(
                                                  categoryToEdit: category,
                                                ),
                                            icon: const Icon(
                                              Icons.edit,
                                              size: 16,
                                              color: Colors.black54,
                                            ),
                                            label: const Text(
                                              'Editar',
                                              style: TextStyle(
                                                color: Colors.black87,
                                              ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                          ),

                                          // BOTÓN ELIMINAR CON CONFIRMACIÓN
                                          OutlinedButton.icon(
                                            onPressed: () async {
                                              // DIÁLOGO DE CONFIRMACIÓN
                                              final confirm = await showDialog<bool>(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text(
                                                    'Eliminar categoría',
                                                  ),
                                                  content: Text(
                                                    '¿Estás seguro de que deseas eliminar la categoría "${category.name}"?\n\nLas notas que pertenezcan a esta categoría no se borrarán, pero se quedarán sin categoría asignada.',
                                                  ),
                                                  actions: [
                                                    // BOTÓN CANCELAR: DEVUELVE FALSE
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                            false,
                                                          ),
                                                      child: const Text(
                                                        'Cancelar',
                                                      ),
                                                    ),
                                                    // BOTÓN ELIMINAR: DEVUELVE TRUE
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                            true,
                                                          ),
                                                      style:
                                                          TextButton.styleFrom(
                                                            foregroundColor:
                                                                Colors.red,
                                                          ),
                                                      child: const Text(
                                                        'Eliminar',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (confirm == true &&
                                                  category.id != null) {
                                                await DatabaseService.instance
                                                    .deleteCategory(
                                                      category.id!,
                                                    );
                                                refreshCategories();

                                                // SNACKBAR INFORMATIVO
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Categoría eliminada',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              size: 16,
                                              color: Colors.red,
                                            ),
                                            label: const Text(
                                              'Eliminar',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
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
