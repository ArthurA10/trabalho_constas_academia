import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';


class SelectExerciseScreen extends ConsumerWidget {
  const SelectExerciseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(exercisesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Selecionar Exercício')),
      body: exercisesAsync.when(
        data: (exercises) {
          return ListView.builder(
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final ex = exercises[index];
              return ListTile(
                title: Text(ex.name),
                subtitle: Text(ex.muscleGroup),
                trailing: const Icon(Icons.add_circle_outline),
                onTap: () => Navigator.pop(context, ex),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erro: $err')),
      ),
    );
  }
}