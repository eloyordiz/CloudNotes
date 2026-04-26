import 'package:flutter/material.dart';
import '../models/note_category.dart';
import '../services/database_service.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<NoteCategory> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshCategories();
  }

  Future<void> _refreshCategories() async {
    setState(() => _isLoading = true);
    _categories = await DatabaseService.instance.readAllCategories();
    setState(() => _isLoading = false);
  }

  // Cuadro de diálogo para crear una nueva categoría
  Future<void> _showAddCategoryDialog() async {
    final nameController = TextEditingController();
    final iconController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Categoría'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: iconController,
              maxLength: 1, // Solo un carácter (un emoji)
              decoration: const InputDecoration(labelText: 'Icono (Emoji)'),
            ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: 'Ej: Universidad',
                labelText: 'Nombre de la categoría',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  iconController.text.isNotEmpty) {
                final newCat = NoteCategory(
                  name: nameController.text,
                  icon: iconController.text,
                  isSynced: false,
                );
                await DatabaseService.instance.createCategory(newCat);
                if (mounted) Navigator.pop(context);
                _refreshCategories(); // Recargamos la lista
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Categorías')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
          ? const Center(child: Text('Aún no tienes categorías'))
          : ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return ListTile(
                  leading: Text(
                    category.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(category.name),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
