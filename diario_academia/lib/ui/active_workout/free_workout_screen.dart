import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models.dart';
import '../../providers/app_providers.dart';
import '../routines/select_exercise_screen.dart';

class FreeWorkoutScreen extends ConsumerStatefulWidget {
  const FreeWorkoutScreen({super.key});

  @override
  ConsumerState<FreeWorkoutScreen> createState() => _FreeWorkoutScreenState();
}

class _FreeWorkoutScreenState extends ConsumerState<FreeWorkoutScreen> {
  final DateTime _startTime = DateTime.now();
  final List<Exercise> _exercises = [];
  final Map<int, List<WorkoutSet>> _workoutSets = {};

  Future<void> _addExercise() async {
    final selected = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute(builder: (_) => const SelectExerciseScreen()),
    );
    
    if (selected != null && !_exercises.any((e) => e.id == selected.id)) {
      setState(() {
        _exercises.add(selected);
        _workoutSets[selected.id!] = [
          WorkoutSet(workoutId: 0, exerciseId: selected.id!, weight: 0, reps: 0, isCompleted: 0)
        ];
      });
    }
  }

  void _addSet(int exerciseId) {
    setState(() {
      _workoutSets[exerciseId]!.add(
        WorkoutSet(workoutId: 0, exerciseId: exerciseId, weight: 0, reps: 0, isCompleted: 0)
      );
    });
  }

  void _updateSet(int exerciseId, int setIndex, double weight, int reps, bool isCompleted) {
    final currentSet = _workoutSets[exerciseId]![setIndex];
    _workoutSets[exerciseId]![setIndex] = WorkoutSet(
      workoutId: currentSet.workoutId,
      exerciseId: exerciseId,
      weight: weight,
      reps: reps,
      isCompleted: isCompleted ? 1 : 0,
    );
    setState(() {}); // Atualiza a UI para o checkbox
  }

  Future<void> _finishWorkout() async {
    List<WorkoutSet> allSetsToSave = [];
    for (var sets in _workoutSets.values) {
      allSetsToSave.addAll(sets.where((s) => s.isCompleted == 1));
    }

    if (allSetsToSave.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conclua pelo menos uma série.')));
      return;
    }

    await ref.read(databaseRepositoryProvider).saveWorkout('Treino Livre', _startTime, DateTime.now(), allSetsToSave);
    
    ref.invalidate(historyProvider);
    ref.invalidate(volumeProvider);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Treino Livre'),
        actions: [
          TextButton(
            onPressed: _finishWorkout,
            child: const Text('FINALIZAR', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: _exercises.isEmpty
          ? Center(
              child: Text('Nenhum exercício adicionado.', style: TextStyle(color: Colors.grey.shade500)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _exercises.length,
              itemBuilder: (context, index) {
                final ex = _exercises[index];
                final sets = _workoutSets[ex.id!]!;

                return Card(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ex.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Divider(),
                        ...List.generate(sets.length, (setIndex) {
                          final currentSet = sets[setIndex];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                SizedBox(width: 30, child: Text('${setIndex + 1}')),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: currentSet.weight == 0 ? '' : currentSet.weight.toString(),
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'Kg', isDense: true),
                                    onChanged: (v) => _updateSet(ex.id!, setIndex, double.tryParse(v) ?? 0, currentSet.reps, currentSet.isCompleted == 1),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: currentSet.reps == 0 ? '' : currentSet.reps.toString(),
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'Reps', isDense: true),
                                    onChanged: (v) => _updateSet(ex.id!, setIndex, currentSet.weight, int.tryParse(v) ?? 0, currentSet.isCompleted == 1),
                                  ),
                                ),
                                Checkbox(
                                  value: currentSet.isCompleted == 1,
                                  onChanged: (v) => _updateSet(ex.id!, setIndex, currentSet.weight, currentSet.reps, v == true),
                                )
                              ],
                            ),
                          );
                        }),
                        TextButton.icon(
                          onPressed: () => _addSet(ex.id!),
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar Série'),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExercise,
        icon: const Icon(Icons.add),
        label: const Text('Exercício'),
      ),
    );
  }
}