import 'package:flutter/widgets.dart';

class Exercise {
  final int? id;
  final String name;
  final String muscleGroup;
  final String? imagePath;
  final int isActive; // 1 para ativo, 0 para excluído (soft delete)
  final String category;

  Exercise({
    this.id,
    required this.name,
    required this.muscleGroup,
    this.imagePath,
    this.isActive = 1,
    this.category = 'musculacao',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'muscleGroup': muscleGroup,
    'imagePath': imagePath,
    'isActive': isActive,
    'category': category,
  };

  factory Exercise.fromMap(Map<String, dynamic> map) => Exercise(
    id: map['id'],
    name: map['name'],
    muscleGroup: map['muscleGroup'],
    imagePath: map['imagePath'],
    isActive: map['isActive'] ?? 1,
    category: map['category'] ?? 'musculacao',
  );
}

class Routine {
  final int? id;
  final String name;
  Routine({this.id, required this.name});

  Map<String, dynamic> toMap() => {'id': id, 'name': name};
  factory Routine.fromMap(Map<String, dynamic> map) =>
      Routine(id: map['id'], name: map['name']);
}

class Workout {
  final int? id;
  final String name; // Vai atuar como o routineNameSnapshot
  final DateTime startTime;
  final DateTime? endTime;

  Workout({this.id, required this.name, required this.startTime, this.endTime});

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
  };

  factory Workout.fromMap(Map<String, dynamic> map) => Workout(
    id: map['id'],
    name: map['name'],
    startTime: DateTime.parse(map['startTime']),
    endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
  );
}

class WorkoutSet {
  final int? id;
  final int workoutId;
  final int exerciseId;
  final String? exerciseNameSnapshot; // Nome congelado para o histórico
  final double weight;
  final int reps;
  final int isCompleted;
  final String uiKey;

  WorkoutSet({
    this.id,
    required this.workoutId,
    required this.exerciseId,
    this.exerciseNameSnapshot,
    required this.weight,
    required this.reps,
    required this.isCompleted,
    String? uiKey,
  }) : uiKey = uiKey ?? UniqueKey().toString(); // O ponto e vírgula foi removido de antes dos ':'

  // O copyWith é essencial para o Riverpod atualizar os dados mantendo o uiKey e o teclado aberto
  WorkoutSet copyWith({
    int? id,
    int? workoutId,
    int? exerciseId,
    String? exerciseNameSnapshot,
    double? weight,
    int? reps,
    int? isCompleted,
    String? uiKey,
  }) {
    return WorkoutSet(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseNameSnapshot: exerciseNameSnapshot ?? this.exerciseNameSnapshot,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      isCompleted: isCompleted ?? this.isCompleted,
      uiKey: uiKey ?? this.uiKey, // Mantém a chave original da tela
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'workoutId': workoutId,
    'exerciseId': exerciseId,
    'exerciseNameSnapshot': exerciseNameSnapshot,
    'weight': weight,
    'reps': reps,
    'isCompleted': isCompleted,
  };

  factory WorkoutSet.fromMap(Map<String, dynamic> map) => WorkoutSet(
    id: map['id'],
    workoutId: map['workoutId'],
    exerciseId: map['exerciseId'],
    exerciseNameSnapshot: map['exerciseNameSnapshot'],
    weight: map['weight'],
    reps: map['reps'],
    isCompleted: map['isCompleted'],
  );
}
