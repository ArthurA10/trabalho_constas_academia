import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models.dart';
import '../../providers/app_providers.dart';
import '../../providers/rest_timer_provider.dart';
import '../../providers/active_workout_session_provider.dart';
import '../widgets/rest_timer_widget.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  final Routine routine;
  const ActiveWorkoutScreen({super.key, required this.routine});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeRoutine();
    });
  }

  Future<void> _initializeRoutine() async {
    final session = ref.read(activeWorkoutSessionProvider);
    // Se o treino dessa rotina ainda não estiver na memória global, carrega do banco
    if (!session.isRunning || session.routine?.id != widget.routine.id) {
      final exercises = await ref.read(databaseRepositoryProvider).getExercisesForRoutine(widget.routine.id!);
      ref.read(activeWorkoutSessionProvider.notifier).startRoutineWorkout(widget.routine, exercises);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _finishWorkout() async {
    final session = ref.read(activeWorkoutSessionProvider);
    List<WorkoutSet> allSetsToSave = [];
    
    for (var sets in session.workoutSets.values) {
      allSetsToSave.addAll(sets.where((s) => s.isCompleted == 1));
    }

    if (allSetsToSave.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conclua pelo menos uma série para guardar.')));
      return;
    }

    await ref.read(databaseRepositoryProvider).saveWorkout(widget.routine.name, session.startTime!, DateTime.now(), allSetsToSave);
    
    ref.invalidate(historyProvider);
    ref.invalidate(volumeProvider);
    ref.read(restTimerProvider.notifier).stopTimer();
    ref.read(activeWorkoutSessionProvider.notifier).discardWorkout();

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final session = ref.watch(activeWorkoutSessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routine.name),
        actions: [
          TextButton(
            onPressed: _finishWorkout,
            child: const Text('FINALIZAR', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: session.exercises.length,
        itemBuilder: (context, index) {
          final ex = session.exercises[index];
          final sets = session.workoutSets[ex.id!] ?? [];

          return Card(
            margin: const EdgeInsets.only(bottom: 24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ex.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      SizedBox(width: 40, child: Text('Série', textAlign: TextAlign.center)),
                      Expanded(child: Text('Peso (kg)', textAlign: TextAlign.center)),
                      Expanded(child: Text('Reps', textAlign: TextAlign.center)),
                      SizedBox(width: 48, child: Icon(Icons.check)),
                    ],
                  ),
                  const Divider(),
                  ...List.generate(sets.length, (setIndex) {
                    final currentSet = sets[setIndex];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          SizedBox(width: 40, child: Text('${setIndex + 1}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: TextFormField(
                                initialValue: currentSet.weight == 0 ? '' : currentSet.weight.toString(),
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.zero),
                                onChanged: (val) => ref.read(activeWorkoutSessionProvider.notifier).updateSet(ex.id!, setIndex, double.tryParse(val) ?? 0, currentSet.reps, currentSet.isCompleted == 1),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: TextFormField(
                                initialValue: currentSet.reps == 0 ? '' : currentSet.reps.toString(),
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.zero),
                                onChanged: (val) => ref.read(activeWorkoutSessionProvider.notifier).updateSet(ex.id!, setIndex, currentSet.weight, int.tryParse(val) ?? 0, currentSet.isCompleted == 1),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 48,
                            child: Checkbox(
                              value: currentSet.isCompleted == 1,
                              onChanged: (val) {
                                ref.read(activeWorkoutSessionProvider.notifier).updateSet(ex.id!, setIndex, currentSet.weight, currentSet.reps, val == true);
                                if (val == true) {
                                  final defaultTime = ref.read(defaultRestTimeProvider);
                                  ref.read(restTimerProvider.notifier).startTimer(defaultTime, exerciseName: ex.name);
                                }
                              },
                              activeColor: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: () => ref.read(activeWorkoutSessionProvider.notifier).addSet(ex.id!),
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar Série'),
                  )
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const RestTimerWidget(),
    );
  }
}