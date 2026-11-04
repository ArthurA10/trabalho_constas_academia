import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models.dart';
import '../../data/database_helper.dart';
import 'create_exercise_screen.dart';

// Provider para carregar a lista de exercícios ativos nesta tela
final manageExercisesProvider = FutureProvider.autoDispose<List<Exercise>>((ref) async {
  return await DatabaseHelper.instance.getActiveExercises();
});

class ExercisesScreen extends ConsumerWidget {
  const ExercisesScreen({super.key});

  void _deleteExercise(BuildContext context, WidgetRef ref, Exercise exercise) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar Exercício?'),
        content: Text('Tem a certeza que deseja apagar "${exercise.name}"? Os treinos antigos não serão afetados.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('APAGAR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && exercise.id != null) {
      await DatabaseHelper.instance.deactivateExercise(exercise.id!);
      ref.invalidate(manageExercisesProvider); // Recarrega a lista
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsyncValue = ref.watch(manageExercisesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Exercícios'),
      ),
      body: exercisesAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erro: $err')),
        data: (exercises) {
          if (exercises.isEmpty) {
            return const Center(child: Text('Nenhum exercício encontrado.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80), // Espaço para o botão flutuante
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final ex = exercises[index];
              final hasImage = ex.imagePath != null && ex.imagePath!.isNotEmpty;
              final isAsset = hasImage && ex.imagePath!.startsWith('assets/');

              void showFullImage() {
                if (!hasImage) return;
                showDialog(
                  context: context,
                  builder: (ctx) => Dialog(
                    backgroundColor: Colors.transparent,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: isAsset
                          ? Image.asset(ex.imagePath!, fit: BoxFit.contain)
                          : Image.file(File(ex.imagePath!), fit: BoxFit.contain),
                    ),
                  ),
                );
              }

              return ListTile(
                leading: GestureDetector(
                  onTap: showFullImage,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: hasImage
                        ? (isAsset
                            ? Image.asset(ex.imagePath!, fit: BoxFit.cover)
                            : Image.file(File(ex.imagePath!), fit: BoxFit.cover))
                        : const Icon(Icons.fitness_center, color: Colors.grey),
                  ),
                ),
                title: Text(ex.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(ex.muscleGroup),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteExercise(context, ref, ex),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final newExercise = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateExerciseScreen()),
          );
          if (newExercise != null) {
            ref.invalidate(manageExercisesProvider);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Novo Exercício'),
      ),
    );
  }
}