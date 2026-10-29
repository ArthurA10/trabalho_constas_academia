import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models.dart';
import '../../providers/app_providers.dart';
import '../../providers/rest_timer_provider.dart';
import '../widgets/rest_timer_widget.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  final Routine routine;
  const ActiveWorkoutScreen({super.key, required this.routine});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  final DateTime _startTime = DateTime.now();
  List<Exercise> _exercises = [];
  bool _isLoading = true;
  
  // Mapa para guardar as séries por exercício (ID do exercício -> Lista de séries)
  final Map<int, List<WorkoutSet>> _workoutSets = {};

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    final exercises = await ref.read(databaseRepositoryProvider).getExercisesForRoutine(widget.routine.id!);
    setState(() {
      _exercises = exercises;
      for (var ex in exercises) {
        // Inicializa com uma série vazia para cada exercício
        _workoutSets[ex.id!] = [
          WorkoutSet(workoutId: 0, exerciseId: ex.id!, weight: 0, reps: 0, isCompleted: 0)
        ];
      }
      _isLoading = false;
    });
  }

  void _addSet(int exerciseId) {
    setState(() {
      _workoutSets[exerciseId]!.add(
        WorkoutSet(workoutId: 0, exerciseId: exerciseId, weight: 0, reps: 0, isCompleted: 0)
      );
    });
  }

  void _toggleSetCompletion(int exerciseId, int setIndex, bool? value) {
    setState(() {
      final currentSet = _workoutSets[exerciseId]![setIndex];
      _workoutSets[exerciseId]![setIndex] = WorkoutSet(
        workoutId: currentSet.workoutId,
        exerciseId: currentSet.exerciseId,
        weight: currentSet.weight,
        reps: currentSet.reps,
        isCompleted: value == true ? 1 : 0,
      );
    });

    // INSERÇÃO NOVA: Dispara o cronómetro quando a série é concluída
    if (value == true) {
      // Inicia um descanso padrão de 90 segundos
      ref.read(restTimerProvider.notifier).startTimer(90); 
    }
  }

  void _updateSetValues(int exerciseId, int setIndex, double weight, int reps) {
    final currentSet = _workoutSets[exerciseId]![setIndex];
    _workoutSets[exerciseId]![setIndex] = WorkoutSet(
      workoutId: currentSet.workoutId,
      exerciseId: currentSet.exerciseId,
      weight: weight,
      reps: reps,
      isCompleted: currentSet.isCompleted,
    );
  }

  Future<void> _finishWorkout() async {
    final endTime = DateTime.now();
    List<WorkoutSet> allSetsToSave = [];
    
    // Filtra apenas as séries marcadas como concluídas
    for (var sets in _workoutSets.values) {
      allSetsToSave.addAll(sets.where((s) => s.isCompleted == 1));
    }

    if (allSetsToSave.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conclua pelo menos uma série para guardar.')));
      return;
    }

    await ref.read(databaseRepositoryProvider).saveWorkout(widget.routine.name, _startTime, endTime, allSetsToSave);

    ref.invalidate(historyProvider);
    ref.invalidate(volumeProvider);
    
    // Para o cronómetro se ainda estiver a correr ao finalizar o treino
    ref.read(restTimerProvider.notifier).stopTimer();
    
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

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
                                onChanged: (val) => _updateSetValues(ex.id!, setIndex, double.tryParse(val) ?? 0, currentSet.reps),
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
                                onChanged: (val) => _updateSetValues(ex.id!, setIndex, currentSet.weight, int.tryParse(val) ?? 0),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 48,
                            child: Checkbox(
                              value: currentSet.isCompleted == 1,
                              onChanged: (val) => _toggleSetCompletion(ex.id!, setIndex, val),
                              activeColor: Colors.green,
                            ),
                          ),
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
      bottomNavigationBar: const RestTimerWidget(),
    );
  }
}