import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/database_service.dart';

class NoteScreen extends StatefulWidget {
  final Note? note;

  const NoteScreen({super.key, this.note});

  @override
  State<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  // VARIABLES DE LA NOTA: COLOR, ARCHIVADO Y CATEGORÍA
  int _selectedColor = 0xFFFFFFFF; // Blanco por defecto
  bool _isArchived = false;
  int? _selectedCategoryId;

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

  @override
  void initState() {
    super.initState();
    // SI WIDGET.NOTE NO ES NULO, ESTAMOS EDITANDO
    // RECUPERAMOS LOS VALORES ORIGINALES DE LA NOTA
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _selectedColor = widget.note!.color;
      _isArchived = widget.note!.isArchived;
      _selectedCategoryId = widget.note!.categoryId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (_titleController.text.isEmpty && _contentController.text.isEmpty) {
      Navigator.pop(context);
      return;
    }

    if (widget.note != null) {
      // ACTUALIZAR NOTA CON NUEVOS VALORES
      final updatedNote = Note(
        id: widget.note!.id,
        categoryId: _selectedCategoryId,
        title: _titleController.text.isEmpty
            ? 'Sin título'
            : _titleController.text,
        content: _contentController.text,
        color: _selectedColor,
        createdAt: widget.note!.createdAt,
        updatedAt: DateTime.now(),
        isArchived: _isArchived,
        isSynced: false,
      );
      await DatabaseService.instance.updateNote(updatedNote);
    } else {
      // CREAR NOTA
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
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // FONDO DEPENDIENTE DEL COLOR SELECCIONADO
      backgroundColor: Color(_selectedColor),
      appBar: AppBar(
        backgroundColor:
            Colors.transparent, // BARRA TRANSPARENTE PARA VER EL FONDO
        elevation: 0,
        title: Text(widget.note != null ? 'Editar Nota' : 'Nueva Nota'),
        actions: [
          // BOTÓN DE ARCHIVAR
          IconButton(
            icon: Icon(
              _isArchived ? Icons.archive : Icons.archive_outlined,
              color: _isArchived ? Colors.blue : null,
            ),
            tooltip: _isArchived ? 'Desarchivar' : 'Archivar',
            onPressed: () {
              setState(() {
                _isArchived = !_isArchived;
              });
            },
          ),
          // BOTÓN DE GUARDAR
          IconButton(icon: const Icon(Icons.check), onPressed: _saveNote),
        ],
      ),
      body: Column(
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
                      keyboardType: TextInputType.multiline,
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _colors.length,
              itemBuilder: (context, index) {
                final color = _colors[index];
                final isSelected = color == _selectedColor;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
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
    );
  }
}
