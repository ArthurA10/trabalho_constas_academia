import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../data/models.dart';
import '../../providers/app_providers.dart';
import '../../data/database_helper.dart';

class CreateExerciseScreen extends ConsumerStatefulWidget {
  const CreateExerciseScreen({super.key});

  @override
  ConsumerState<CreateExerciseScreen> createState() =>
      _CreateExerciseScreenState();
}

class _CreateExerciseScreenState extends ConsumerState<CreateExerciseScreen> {
  String _selectedCategory = 'musculacao'; // Variável da categoria
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _muscleGroupController =
      TextEditingController(); // O controlador do grupo muscular está aqui

  String? _selectedMuscleGroup;

  //Lista exata de categorias de grupo muscular
  final List<String> _categorias = [
    'Peito',
    'Costas',
    'Quadríceps',
    'Posterior',
    'Glúteos',
    'Ombros',
    'Bíceps',
    'Tríceps',
    'Panturrilha',
    'Antebraço',
    'Abdômen',
    'Cardio',
  ];

  File? _selectedImage;
  bool _isSaving = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _saveImagePermanently(File imageFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final savedImage = File('${directory.path}/$fileName');

      await imageFile.copy(savedImage.path);
      return savedImage.path;
    } catch (e) {
      debugPrint('Erro ao guardar imagem: $e');
      return null;
    }
  }

  Future<void> _saveExercise() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    String? permanentImagePath;
    if (_selectedImage != null) {
      permanentImagePath = await _saveImagePermanently(_selectedImage!);
    }

    final newExercise = Exercise(
      name: _nameController.text.trim(),
      muscleGroup: _muscleGroupController.text
          .trim(), // Salvando o grupo muscular
      imagePath: permanentImagePath,
      isActive: 1,
      category: _selectedCategory, // ADICIONADO: Salvando a categoria (Musculação ou Cardio)
    );

    await DatabaseHelper.instance.addExercise(newExercise);

    ref.invalidate(exercisesProvider);

    if (mounted) {
      Navigator.pop(context, newExercise);
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Tirar Foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Escolher da Galeria'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _muscleGroupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Exercício')),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      onTap: _showImagePickerOptions,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: _selectedImage != null
                            ? Image.file(_selectedImage!, fit: BoxFit.cover)
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.add_a_photo,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Adicionar Foto do Equipamento',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Exercício *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Campo obrigatório'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedMuscleGroup,
                      decoration: const InputDecoration(
                        labelText: 'Grupo Muscular',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.accessibility_new),
                      ),
                      items: _categorias.map((String categoria) {
                        return DropdownMenuItem<String>(
                          value: categoria,
                          child: Text(categoria),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedMuscleGroup = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo obrigatório';
                        }
                        return null;
                      },
                    ),

                    // ADICIONADO: Dropdown de Categoria
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Categoria do Exercício',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'musculacao',
                          child: Text('Musculação (Peso x Reps)'),
                        ),
                        DropdownMenuItem(
                          value: 'cardio',
                          child: Text('Cardio (Distância x Tempo)'),
                        ),
                      ],
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedCategory = newValue;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saveExercise,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'SALVAR EXERCÍCIO',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
