class Exercise {
  final int? id;
  final String name;
  final String muscleGroup;
  final String equipment;
  final String category;

  Exercise({this.id, required this.name, required this.muscleGroup, required this.equipment, required this.category});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'muscleGroup': muscleGroup,
      'equipment': equipment,
      'category': category,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'],
      name: map['name'],
      muscleGroup: map['muscleGroup'],
      equipment: map['equipment'],
      category: map['category'],
    );
  }
}

class Routine {
  final int? id;
  final String name;

  Routine({this.id, required this.name});

  Map<String, dynamic> toMap() => {'id': id, 'name': name};
  
  factory Routine.fromMap(Map<String, dynamic> map) {
    return Routine(id: map['id'], name: map['name']);
  }
}

class Workout {
  final int? id;
  final String name;
  final DateTime startTime;
  final DateTime? endTime;
  final int isCompleted; // 0 para falso, 1 para verdadeiro (SQLite)

  Workout({this.id, required this.name, required this.startTime, this.endTime, this.isCompleted = 0});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'],
      name: map['name'],
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      isCompleted: map['isCompleted'],
    );
  }
}

class WorkoutSet {
  final int? id;
  final int workoutId;
  final int exerciseId;
  final double weight;
  final int reps;
  final int isCompleted;

  WorkoutSet({
    this.id,
    required this.workoutId,
    required this.exerciseId,
    required this.weight,
    required this.reps,
    this.isCompleted = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workoutId': workoutId,
      'exerciseId': exerciseId,
      'weight': weight,
      'reps': reps,
      'isCompleted': isCompleted,
    };
  }

  factory WorkoutSet.fromMap(Map<String, dynamic> map) {
    return WorkoutSet(
      id: map['id'],
      workoutId: map['workoutId'],
      exerciseId: map['exerciseId'],
      weight: map['weight'],
      reps: map['reps'],
      isCompleted: map['isCompleted'],
    );
  }
}