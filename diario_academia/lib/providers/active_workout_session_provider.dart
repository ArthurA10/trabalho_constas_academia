import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // --- ADIÇÃO: Métodos para converter o Treino em JSON e vice-versa ---
  Map<String, dynamic> toMap() => {
        'isRunning': isRunning,
        'title': title,
        'type': type,
        'routine': routine?.toMap(),
        'startTime': startTime?.toIso8601String(),
        'exercises': exercises.map((e) => e.toMap()).toList(),
        // O JSON só aceita Strings como chaves de Map, então convertemos o ID do exercício (int) para String
        'workoutSets': workoutSets.map((key, value) => MapEntry(key.toString(), value.map((s) => s.toMap()).toList())),
      };

  factory ActiveWorkoutSession.fromMap(Map<String, dynamic> map) => ActiveWorkoutSession(
        isRunning: map['isRunning'] ?? false,
        title: map['title'] ?? '',
        type: map['type'] ?? '',
        routine: map['routine'] != null ? Routine.fromMap(map['routine']) : null,
        startTime: map['startTime'] != null ? DateTime.parse(map['startTime']) : null,
        exercises: (map['exercises'] as List?)?.map((e) => Exercise.fromMap(e)).toList() ?? [],
        workoutSets: (map['workoutSets'] as Map<String, dynamic>?)?.map((key, value) => MapEntry(
              int.parse(key),
              (value as List).map((s) => WorkoutSet.fromMap(s)).toList(),
            )) ?? {},
      );
}

class ActiveWorkoutSessionNotifier extends Notifier<ActiveWorkoutSession> {
  static const _draftKey = 'active_workout_draft';

  @override
  ActiveWorkoutSession build() {
    _loadDraft(); // Carrega automaticamente se o app foi fechado no meio do treino
    return ActiveWorkoutSession();
  }

  // --- LÓGICA DO RASCUNHO ---
  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draftStr = prefs.getString(_draftKey);
    if (draftStr != null) {
      state = ActiveWorkoutSession.fromMap(jsonDecode(draftStr));
    }
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    if (state.isRunning) {
      await prefs.setString(_draftKey, jsonEncode(state.toMap()));
    } else {
      await prefs.remove(_draftKey); // Limpa o rascunho se não houver treino rodando
    }
  }

  // --- MÉTODOS DO TREINO ---
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
    _saveDraft();
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
    _saveDraft();
  }

  void addExercise(Exercise exercise) {
    if (state.exercises.any((e) => e.id == exercise.id)) return;
    final newExercises = List<Exercise>.from(state.exercises)..add(exercise);
    final newSets = Map<int, List<WorkoutSet>>.from(state.workoutSets);
    newSets[exercise.id!] = [
      WorkoutSet(workoutId: 0, exerciseId: exercise.id!, weight: 0, reps: 0, isCompleted: 0)
    ];
    state = state.copyWith(exercises: newExercises, workoutSets: newSets);
    _saveDraft();
  }

  void addSet(int exerciseId) {
    final newSets = Map<int, List<WorkoutSet>>.from(state.workoutSets);
    final currentSets = List<WorkoutSet>.from(newSets[exerciseId]!);

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
      isCompleted: 0,
    ));
    newSets[exerciseId] = currentSets;
    state = state.copyWith(workoutSets: newSets);
    _saveDraft();
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
      _saveDraft(); // Salva a cada alteração de peso/check
    }
  }

  void removeSet(int exerciseId, int setIndex) {
    final currentSets = List<WorkoutSet>.from(state.workoutSets[exerciseId] ?? []);

    if (currentSets.length > setIndex) {
      currentSets.removeAt(setIndex);

      final updatedWorkoutSets = Map<int, List<WorkoutSet>>.from(state.workoutSets);
      updatedWorkoutSets[exerciseId] = currentSets;

      state = state.copyWith(workoutSets: updatedWorkoutSets);
      _saveDraft();
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
    _saveDraft();
  }

  void discardWorkout() {
    state = ActiveWorkoutSession();
    _saveDraft(); // Como o state não está mais rodando, o _saveDraft vai apagar a memória cache
  }

  Future<bool> finishWorkout() async {
    if (state.startTime == null) return false;

    List<WorkoutSet> allSetsToSave = [];
    for (var sets in state.workoutSets.values) {
      allSetsToSave.addAll(
        sets.where((s) => s.isCompleted == 1 && s.weight > 0 && s.reps > 0),
      );
    }

    if (allSetsToSave.isEmpty) return false;

    final endTime = DateTime.now();
    final routineName = state.routine?.name ?? state.title;

    await ref.read(databaseRepositoryProvider).saveWorkout(
      routineName,
      state.startTime!,
      endTime,
      allSetsToSave,
    );

    if (state.routine != null) {
      final exerciseIds = state.exercises.map((e) => e.id!).toList();
      await ref.read(databaseRepositoryProvider).updateRoutineExercises(state.routine!.id!, exerciseIds);
    }

    discardWorkout();
    return true;
  }
}

final activeWorkoutSessionProvider = NotifierProvider<ActiveWorkoutSessionNotifier, ActiveWorkoutSession>(() {
  return ActiveWorkoutSessionNotifier();
});