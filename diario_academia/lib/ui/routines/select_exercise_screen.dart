
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models.dart';
import '../../data/database_helper.dart';
import '../../providers/app_providers.dart'; 

// Provider temporário para carregar a lista nesta tela
final activeExercisesProvider = FutureProvider.autoDispose<List<Exercise>>((ref) async {
  return await DatabaseHelper.instance.getActiveExercises();
});

class SelectExerciseScreen extends ConsumerWidget {
  const SelectExerciseScreen({super.key});

  void _deleteExercise(BuildContext context, WidgetRef ref, Exercise exercise) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar Exercício?'),
        content: Text('Tem certeza que deseja apagar "${exercise.name}"? Os treinos antigos não serão afetados.'),
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
      ref.invalidate(activeExercisesProvider); // Atualiza a lista na hora
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Corrigido para chamar o provider definido no topo deste arquivo
    final exercisesAsync = ref.watch(activeExercisesProvider); 
    final currentFilter = ref.watch(exerciseFilterProvider);

    // Defina as categorias conforme estão salvas no seu banco de dados
    final categories = ['Todos', 'Peito', 'Costas', 'Quadríceps', 'Posterior', 'Glúteos', 'Ombros', 'Bíceps', 'Tríceps', 'Panturrilha', 'Antebraço', 'Abdômen'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Exercício'),
      ),
      body: Column(
        children: [
          // --- BARRA DE FILTROS HORIZONTAL ---
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: currentFilter == category,
                    onSelected: (selected) {
                      if (selected) {
                        // Atualizado para usar o padrão Notifier moderno
                        ref.read(exerciseFilterProvider.notifier).setFilter(category);
                      }
                    },
                  ),
                );
              },
            ),
          ),
          
          // --- LISTA DE EXERCÍCIOS FILTRADA ---
          Expanded(
            child: exercisesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Erro: $err')),
              data: (allExercises) {
                // Aplica o filtro na lista que veio do banco
                final filteredExercises = currentFilter == 'Todos'
                    ? allExercises
                    : allExercises.where((e) => e.muscleGroup == currentFilter).toList();

                if (filteredExercises.isEmpty) {
                  return const Center(child: Text('Nenhum exercício encontrado.'));
                }

                return ListView.builder(
                  itemCount: filteredExercises.length,
                  itemBuilder: (context, index) {
                    final exercise = filteredExercises[index];
                    return ListTile(
                      title: Text(exercise.name),
                      subtitle: Text(exercise.muscleGroup),
                      // Botão de deletar adicionado para utilizar a função _deleteExercise
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _deleteExercise(context, ref, exercise),
                      ),
                      onTap: () {
                        // Retorna o exercício selecionado para a tela anterior
                        Navigator.pop(context, exercise);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}