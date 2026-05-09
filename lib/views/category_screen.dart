import 'package:cloud_notes/services/auth_service.dart';
import 'package:cloud_notes/services/firestore_service.dart';
import 'package:flutter/material.dart';
import '../models/note_category.dart';
import '../services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  // VARIABLE DEL USUARIO QUE ESTÁ LOGGEADO
  // LA SACAMOS TANTO AQUÍ COMO DENTRO DEL BUILD PARA QUE SE CARGUE AL INICIO Y DINÁMICAMENTE
  final uid = FirebaseAuth.instance.currentUser?.uid;

  // VARIABLE DE CATEGORÍA SELECCIONADA
  NoteCategory? _selectedCategory;
  bool _isCreating = false;

  // CONTROLADORES PARA EL FORMULARIO
  final TextEditingController _nameController = TextEditingController();
  IconData? _selectedIcon;

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

    categories = await DatabaseService.instance.readAllCategories(uid ?? '');
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
                        userId: uid ?? '',
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
                        userId: uid ?? '',
                        name: nameController.text,
                        iconCodePoint: selectedIconCode,
                        createdAt: DateTime.now(),
                      );

                      // GUARDAMOS EN BD LOCAL Y CAPTURAMOS ID
                      final int generatedId = await DatabaseService.instance
                          .createCategory(newCategory);
                      // CREAMOS LA COPIA DE LA NOTA PARA LA NUBE
                      final NoteCategory categoriaConId = newCategory.copyWith(
                        id: generatedId,
                      );
                      // GUARDAMOS LA COPIA EN LA NUBE
                      await FirestoreService().saveCategoryToCloud(
                        categoriaConId,
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
    // VARIABLE DEL USUARIO QUE ESTÁ LOGGEADO
    final currentUser = FirebaseAuth.instance.currentUser;

    // VARIABLE PARA SABER SI ESTAMOS EN UN MÓVIL O DESKTOP
    // PONEMOS EL BREAKPOINT EN 1000 DE ANCHO
    final bool isMobile = MediaQuery.of(context).size.width < 1000;

    // FILTRO DEL BUSCADOR
    final filteredCategories = categories.where((cat) {
      return cat.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    //GUARDAMOS MENÚ LATERAL EN UNA VARIABLE PARA PODER REUTILIZAR CÓDIGO EN MOVIL Y DESKTOP
    /* MENÚ LATERAL. LO DIVIDIMOS EN:
        - LOGO DE LA APP
        - SECCIÓN SUPERIOR: TODAS LAS NOTAS, CATEGORÍAS, Y ARCHIVADAS
        - SINCRONIZACIÓN
        - USUARIO
    */
    final widgetMenuLateral = Container(
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
                    if (isMobile) Navigator.pop(context);
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
                    if (isMobile) Navigator.pop(context);
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
            title: Text(
              currentUser?.displayName ?? 'Usuario',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              currentUser?.email ?? 'Email',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),

          // BOTÓN DE CERRAR SESIÓN
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () async {
                await AuthService().signOut();
              },
              icon: const Icon(Icons.logout, size: 18, color: Colors.black87),
              label: const Text(
                'Cerrar sesión',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: isMobile ? AppBar(title: const Text('CloudNotes')) : null,
      drawer: isMobile ? Drawer(child: widgetMenuLateral) : null,

      /* DIVIDIMOS LA PANTALLA EN 2 COLUMNAS, DE IZQUIERDA A DERECHA:
      - MENÚ LATERAL: ANCHO FIJO, CONTINENE LOGO Y NAVEGACIÓN
      - GESTIÓN DE CATEGORÍAS: ANCHO VARIABLE, CONTIENE LAS CATEGORÍAS , ACCIONES Y BUSCADOR
      */
      body: Row(
        children: [
          // 1. MENÚ LATERAL
          if (!isMobile) widgetMenuLateral,

          // 2. GESTIÓN DE CATEGORÍAS
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PARTE SUPERIOR: TÍTULO, BUSCADOR Y BOTÓN CREAR
                  isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Categorías',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // BUSCADOR EN MÓVIL (Ocupa todo el ancho)
                            TextField(
                              controller: _searchController,
                              onChanged: (val) =>
                                  setState(() => _searchQuery = val),
                              decoration: InputDecoration(
                                hintText: 'Buscar categoría...',
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
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            //TÍTULO
                            const Text(
                              'Categorías',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            //BUSCADOR Y BOTÓN (+)
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
                                      prefixIcon: const Icon(
                                        Icons.search,
                                        size: 20,
                                      ),
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
                                if (!isMobile) ...[
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
                                    child: const Text(
                                      'Crear Nueva Categoría (+)',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                ],
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
                                  maxCrossAxisExtent: 520,
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

      //BOTÓN FLOTANTE PARA CREAR NUEVA CATEGORÍA EN MÓVIL
      floatingActionButton: isMobile
          ? FloatingActionButton(
              heroTag: 'catNewCategory',
              onPressed: () => _showCategoryDialog(),
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
