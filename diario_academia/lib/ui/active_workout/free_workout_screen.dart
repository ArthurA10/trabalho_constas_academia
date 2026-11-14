import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models.dart';
import '../../providers/app_providers.dart';
import '../routines/select_exercise_screen.dart';
import '../../providers/rest_timer_provider.dart';
import '../../providers/active_workout_session_provider.dart';
import '../widgets/rest_timer_widget.dart';
import '../../providers/settings_provider.dart';

class FreeWorkoutScreen extends ConsumerStatefulWidget {
  const FreeWorkoutScreen({super.key});

  @override
  ConsumerState<FreeWorkoutScreen> createState() => _FreeWorkoutScreenState();
}

class _FreeWorkoutScreenState extends ConsumerState<FreeWorkoutScreen> {
  @override
  void initState() {
    super.initState();
    // Garante que a sessão exista na memória ao abrir a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activeWorkoutSessionProvider.notifier).startFreeWorkout();
    });
  }

  Future<void> _addExercise() async {
    final selected = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute(builder: (_) => const SelectExerciseScreen()),
    );
    if (selected != null) {
      ref.read(activeWorkoutSessionProvider.notifier).addExercise(selected);
    }
  }

  Future<void> _finishWorkout() async {
    final session = ref.read(activeWorkoutSessionProvider);
    List<WorkoutSet> allSetsToSave = [];

    // Filtra apenas séries concluídas E com valores válidos
    for (var sets in session.workoutSets.values) {
      allSetsToSave.addAll(
        sets.where((s) => s.isCompleted == 1 && s.weight > 0 && s.reps > 0),
      );
    }

    if (allSetsToSave.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conclua pelo menos uma série válida.'),
          behavior: SnackBarBehavior.floating, // Faz a mensagem flutuar
          margin: EdgeInsets.only(bottom: 3, left: 16, right: 16),
        ),
      );
      return;
    }

    await ref
        .read(databaseRepositoryProvider)
        .saveWorkout(
          'Treino Livre',
          session.startTime!,
          DateTime.now(),
          allSetsToSave,
        );

    ref.invalidate(historyProvider);
    ref.invalidate(volumeProvider);
    ref.read(restTimerProvider.notifier).stopTimer();
    ref.read(activeWorkoutSessionProvider.notifier).discardWorkout();

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(activeWorkoutSessionProvider);
    final settings = ref.watch(settingsProvider);
    final pesoLabel = settings.useLbs ? 'Lbs' : 'Kg'; 

    return Scaffold(
      appBar: AppBar(
        title: const Text('Treino Livre'),
        actions: [
          TextButton(
            onPressed: _finishWorkout,
            child: const Text(
              'FINALIZAR',
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: session.exercises.isEmpty
          ? Center(
              child: Text(
                'Nenhum exercício adicionado.',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: session.exercises.length,
              itemBuilder: (context, index) {
                final ex = session.exercises[index];
                final sets = session.workoutSets[ex.id!] ?? [];

                // --- LÓGICA DE CATEGORIA ADICIONADA AQUI ---
                String label1 = pesoLabel;
                String label2 = 'Reps';
                
                if (ex.category == 'cardio') {
                  label1 = 'Km'; // Usa o campo weight para distância
                  label2 = 'Min'; // Usa o campo reps para tempo
                } else if (ex.category == 'peso_corporal') {
                  label1 = '+$pesoLabel'; // Representa peso extra
                  label2 = 'Reps';
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ex.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        ...List.generate(sets.length, (setIndex) {
                          final currentSet = sets[setIndex];
                          return Padding(
                            key: ValueKey(currentSet.uiKey),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 30,
                                  child: Text('${setIndex + 1}'),
                                ),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: currentSet.weight == 0
                                        ? ''
                                        : currentSet.weight.toString(),
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: label1, // Rótulo dinâmico
                                      isDense: true,
                                    ),
                                    onChanged: (v) => ref
                                        .read(
                                          activeWorkoutSessionProvider.notifier,
                                        )
                                        .updateSet(
                                          ex.id!,
                                          setIndex,
                                          double.tryParse(v) ?? 0,
                                          currentSet.reps,
                                          currentSet.isCompleted == 1,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: currentSet.reps == 0
                                        ? ''
                                        : currentSet.reps.toString(),
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: label2, // Rótulo dinâmico
                                      isDense: true,
                                    ),
                                    onChanged: (v) => ref
                                        .read(
                                          activeWorkoutSessionProvider.notifier,
                                        )
                                        .updateSet(
                                          ex.id!,
                                          setIndex,
                                          currentSet.weight,
                                          int.tryParse(v) ?? 0,
                                          currentSet.isCompleted == 1,
                                        ),
                                  ),
                                ),

                                if (currentSet.isCompleted == 0)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.red,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      ref
                                          .read(
                                            activeWorkoutSessionProvider
                                                .notifier,
                                          )
                                          .removeSet(ex.id!, setIndex);
                                    },
                                  ),
                                Checkbox(
                                  value: currentSet.isCompleted == 1,
                                  onChanged: (val) {
                                    if (val == true) {
                                      if (currentSet.weight <= 0 ||
                                          currentSet.reps <= 0) {
                                            
                                        // Mensagem de erro dinâmica baseada na categoria
                                        final errorMessage = ex.category == 'cardio'
                                            ? 'Preencha a distância e o tempo antes de concluir!'
                                            : 'Preencha o peso e as repetições antes de concluir a série!';

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(errorMessage),
                                            behavior: SnackBarBehavior.floating,
                                            margin: const EdgeInsets.only(
                                              bottom: 5,
                                              left: 16,
                                              right: 16,
                                            ),
                                          ),
                                        );
                                        return; 
                                      }

                                      final tempoPadrao = ref
                                          .read(settingsProvider)
                                          .defaultRestTime;
                                      ref
                                          .read(restTimerProvider.notifier)
                                          .startTimer(
                                            tempoPadrao,
                                            exerciseName: ex.name,
                                          );
                                    }

                                    ref
                                        .read(
                                          activeWorkoutSessionProvider.notifier,
                                        )
                                        .updateSet(
                                          ex.id!,
                                          setIndex,
                                          currentSet.weight,
                                          currentSet.reps,
                                          val == true,
                                        );
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                        TextButton.icon(
                          onPressed: () => ref
                              .read(activeWorkoutSessionProvider.notifier)
                              .addSet(ex.id!),
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar Série'),
                        ),
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
      bottomNavigationBar: const RestTimerWidget(),
    );
  }
}