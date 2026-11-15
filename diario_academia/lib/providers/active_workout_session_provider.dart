import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models.dart';
import 'app_providers.dart';

class ActiveWorkoutSession {
  final bool isRunning;
  final String title;
  final String type; 
  final Routine? routine;
  final DateTime? startTime;
  final List<Exercise> exercises;
  final Map<int, List<WorkoutSet>> workoutSets;

  ActiveWorkoutSession({
    this.isRunning = false,
    this.title = '',
    this.type = '',
    this.routine,
    this.startTime,
    this.exercises = const [],
    this.workoutSets = const {},
  });

  ActiveWorkoutSession copyWith({
    bool? isRunning,
    String? title,
    String? type,
    Routine? routine,
    DateTime? startTime,
    List<Exercise>? exercises,
    Map<int, List<WorkoutSet>>? workoutSets,
  }) {
    return ActiveWorkoutSession(
      isRunning: isRunning ?? this.isRunning,
      title: title ?? this.title,
      type: type ?? this.type,
      routine: routine ?? this.routine,
      startTime: startTime ?? this.startTime,
      exercises: exercises ?? this.exercises,
      workoutSets: workoutSets ?? this.workoutSets,
    );
  }
}

class ActiveWorkoutSessionNotifier extends Notifier<ActiveWorkoutSession> {
  @override
  ActiveWorkoutSession build() => ActiveWorkoutSession();

  void startFreeWorkout() {
    if (state.isRunning) return;
    state = ActiveWorkoutSession(
      isRunning: true,
      title: 'Treino Livre',
      type: 'livre',
      startTime: DateTime.now(),
      exercises: [],
      workoutSets: {},
    );
  }

  void startRoutineWorkout(Routine routine, List<Exercise> exercises) {
    if (state.isRunning && state.routine?.id == routine.id) return;

    final Map<int, List<WorkoutSet>> initialSets = {};
    for (var ex in exercises) {
      initialSets[ex.id!] = [
        WorkoutSet(workoutId: 0, exerciseId: ex.id!, weight: 0, reps: 0, isCompleted: 0)
      ];
    }

    state = ActiveWorkoutSession(
      isRunning: true,
      title: routine.name,
      type: 'rotina',
      routine: routine,
      startTime: DateTime.now(),
      exercises: exercises,
      workoutSets: initialSets,
    );
  }

  void addExercise(Exercise exercise) {
    if (state.exercises.any((e) => e.id == exercise.id)) return;
    final newExercises = List<Exercise>.from(state.exercises)..add(exercise);
    final newSets = Map<int, List<WorkoutSet>>.from(state.workoutSets);
    newSets[exercise.id!] = [
      WorkoutSet(workoutId: 0, exerciseId: exercise.id!, weight: 0, reps: 0, isCompleted: 0)
    ];
    state = state.copyWith(exercises: newExercises, workoutSets: newSets);
  }

  void addSet(int exerciseId) {
    final newSets = Map<int, List<WorkoutSet>>.from(state.workoutSets);
    final currentSets = List<WorkoutSet>.from(newSets[exerciseId]!);
    
    // Pega o peso e repetição da última série
    double lastWeight = 0;
    int lastReps = 0;
    if (currentSets.isNotEmpty) {
      lastWeight = currentSets.last.weight;
      lastReps = currentSets.last.reps;
    }

    currentSets.add(WorkoutSet(
      workoutId: 0, 
      exerciseId: exerciseId, 
      weight: lastWeight, 
      reps: lastReps, 
      isCompleted: 0
    ));
    newSets[exerciseId] = currentSets;
    state = state.copyWith(workoutSets: newSets);
  }

  void updateSet(int exerciseId, int setIndex, double weight, int reps, bool isCompleted) {
    final currentSets = List<WorkoutSet>.from(state.workoutSets[exerciseId] ?? []);
    
    if (setIndex >= 0 && setIndex < currentSets.length) {
      final oldSet = currentSets[setIndex];
      
      currentSets[setIndex] = oldSet.copyWith(
        weight: weight,
        reps: reps,
        isCompleted: isCompleted ? 1 : 0,
      );
      
      final updatedWorkoutSets = Map<int, List<WorkoutSet>>.from(state.workoutSets);
      updatedWorkoutSets[exerciseId] = currentSets;
      
      state = state.copyWith(workoutSets: updatedWorkoutSets);
    }
  }

  void discardWorkout() {
    state = ActiveWorkoutSession();
  }

  void removeSet(int exerciseId, int setIndex) {
    final currentSets = List<WorkoutSet>.from(state.workoutSets[exerciseId] ?? []);
    
    if (currentSets.length > setIndex) {
      currentSets.removeAt(setIndex); 
      
      final updatedWorkoutSets = Map<int, List<WorkoutSet>>.from(state.workoutSets);
      updatedWorkoutSets[exerciseId] = currentSets;
      
      state = state.copyWith(workoutSets: updatedWorkoutSets);
    }
  }

  void removeExercise(int exerciseId) {
    final updatedExercises = state.exercises.where((e) => e.id != exerciseId).toList();
    
    final updatedSets = Map<int, List<WorkoutSet>>.from(state.workoutSets);
    updatedSets.remove(exerciseId);
    
    state = state.copyWith(
      exercises: updatedExercises,
      workoutSets: updatedSets,
    );
  }

  // 9. Finaliza e salva o treino
  Future<bool> finishWorkout() async {
    if (state.startTime == null) return false;

    // Filtra APENAS as séries que foram concluídas (isCompleted == 1)
    List<WorkoutSet> allSetsToSave = [];
    for (var sets in state.workoutSets.values) {
      allSetsToSave.addAll(
        sets.where((s) => s.isCompleted == 1 && s.weight > 0 && s.reps > 0),
      );
    }

    // Se o usuário não concluiu nenhuma série válida, retornamos false
    if (allSetsToSave.isEmpty) {
      return false;
    }

    final endTime = DateTime.now();
    final routineName = state.routine?.name ?? state.title;

    // Acessa o repositório nativamente com ref.read para salvar o Histórico
    await ref.read(databaseRepositoryProvider).saveWorkout(
      routineName,
      state.startTime!,
      endTime,
      allSetsToSave,
    );

    // Salva a nova lista de exercícios na rotina original (caso tenha editado)
    if (state.routine != null) {
      final exerciseIds = state.exercises.map((e) => e.id!).toList();
      await ref.read(databaseRepositoryProvider).updateRoutineExercises(state.routine!.id!, exerciseIds);
    }

    // Limpa a tela de treino ativo:
    discardWorkout(); 
    return true;
  }
}

final activeWorkoutSessionProvider = NotifierProvider<ActiveWorkoutSessionNotifier, ActiveWorkoutSession>(() {
  return ActiveWorkoutSessionNotifier();
});