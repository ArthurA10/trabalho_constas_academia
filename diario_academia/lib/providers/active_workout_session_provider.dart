import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models.dart';

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
    if (state.isRunning) return; // Retoma se já estiver rodando
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
    currentSets.add(WorkoutSet(workoutId: 0, exerciseId: exerciseId, weight: 0, reps: 0, isCompleted: 0));
    newSets[exerciseId] = currentSets;
    state = state.copyWith(workoutSets: newSets);
  }

  void updateSet(int exerciseId, int setIndex, double weight, int reps, bool isCompleted) {
    final newSets = Map<int, List<WorkoutSet>>.from(state.workoutSets);
    final currentSets = List<WorkoutSet>.from(newSets[exerciseId]!);
    final oldSet = currentSets[setIndex];
    currentSets[setIndex] = WorkoutSet(
      workoutId: oldSet.workoutId,
      exerciseId: exerciseId,
      weight: weight,
      reps: reps,
      isCompleted: isCompleted ? 1 : 0,
    );
    newSets[exerciseId] = currentSets;
    state = state.copyWith(workoutSets: newSets);
  }

  void discardWorkout() {
    state = ActiveWorkoutSession();
  }
}

final activeWorkoutSessionProvider = NotifierProvider<ActiveWorkoutSessionNotifier, ActiveWorkoutSession>(() {
  return ActiveWorkoutSessionNotifier();
});