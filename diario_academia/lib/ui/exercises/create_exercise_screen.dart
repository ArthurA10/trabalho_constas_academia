import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';

class CreateExerciseScreen extends ConsumerStatefulWidget {
  const CreateExerciseScreen({super.key});

  @override
  ConsumerState<CreateExerciseScreen> createState() => _CreateExerciseScreenState();
}

class _CreateExerciseScreenState extends ConsumerState<CreateExerciseScreen> {
  final _nameController = TextEditingController();
  String _selectedMuscle = 'Peito';
  final List<String> _muscleGroups = ['Peito', 'Costas', 'Pernas', 'Braços', 'Ombros', 'Core', 'Cardio'];

  Future<void> _saveExercise() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insira o nome do exercício')));
      return;
    }

    await ref.read(databaseRepositoryProvider).createExercise(
      _nameController.text.trim(),
      _selectedMuscle,
    );

    ref.invalidate(exercisesProvider);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Exercício'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveExercise,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome do Exercício',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Grupo Muscular', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedMuscle,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _muscleGroups.map((muscle) {
                return DropdownMenuItem(value: muscle, child: Text(muscle));
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedMuscle = value);
              },
            ),
          ],
        ),
      ),
    );
  }
}