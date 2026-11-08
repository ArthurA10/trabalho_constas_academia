import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database_helper.dart'; // Certifique-se de que o arquivo foi renomeado
import '../data/models.dart';

final volumeProvider = FutureProvider<double>((ref) async {
  return ref.read(databaseRepositoryProvider).getTotalVolume();
});
final historyProvider = FutureProvider<List<Workout>>((ref) async {
  return ref.read(databaseRepositoryProvider).getWorkouts();
});
// Provedor para buscar a lista de exercícios
final exercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  final db = await DatabaseHelper.instance.database;
  final maps = await db.query('exercises', orderBy: 'name ASC');
  return maps.map((e) => Exercise.fromMap(e)).toList();
});

// Provedor para buscar a lista de rotinas
final routinesProvider = FutureProvider<List<Routine>>((ref) async {
  final db = await DatabaseHelper.instance.database;
  final maps = await db.query('routines', orderBy: 'name ASC');
  return maps.map((e) => Routine.fromMap(e)).toList();
});

final databaseRepositoryProvider = Provider((ref) => DatabaseRepository());

class DatabaseRepository {
  Future<void> createRoutineWithExercises(
    String name,
    List<Exercise> exercises,
  ) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      final routineId = await txn.insert('routines', {'name': name});
      for (var ex in exercises) {
        await txn.insert('routine_exercises', {
          'routineId': routineId,
          'exerciseId': ex.id,
        });
      }
    });
  }

  Future<List<Exercise>> getExercisesForRoutine(int routineId) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT e.* FROM exercises e
      INNER JOIN routine_exercises re ON e.id = re.exerciseId
      WHERE re.routineId = ?
    ''',
      [routineId],
    );
    return maps.map((e) => Exercise.fromMap(e)).toList();
  }

  Future<void> saveWorkout(
    String name,
    DateTime startTime,
    DateTime endTime,
    List<WorkoutSet> sets,
  ) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      final workoutId = await txn.insert('workouts', {
        'name': name,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'isCompleted': 1,
      });

      for (var set in sets) {
        await txn.insert('workout_sets', {
          'workoutId': workoutId, // ID gerado acima
          'exerciseId': set.exerciseId,
          'weight': set.weight,
          'reps': set.reps,
          'isCompleted': set.isCompleted,
        });
      }
    });
  }

  Future<List<Workout>> getWorkouts() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('workouts', orderBy: 'startTime DESC');
    return maps.map((e) => Workout.fromMap(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getWorkoutSetsWithExercises(
    int workoutId,
  ) async {
    final db = await DatabaseHelper.instance.database;
    return await db.rawQuery(
      '''
      SELECT ws.*, e.name as exerciseName
      FROM workout_sets ws
      LEFT JOIN exercises e ON ws.exerciseId = e.id
      WHERE ws.workoutId = ?
    ''',
      [workoutId],
    );
  }

  // Calcula o volume total (peso x repetições) de todas as séries concluídas
  Future<double> getTotalVolume() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('''
      SELECT SUM(ws.weight * ws.reps) as volume 
      FROM workout_sets ws
      INNER JOIN workouts w ON ws.workoutId = w.id
      WHERE w.isCompleted = 1 AND ws.isCompleted = 1
    ''');
    final volume = result.first['volume'];
    return volume != null ? (volume as num).toDouble() : 0.0;
  }

  Future<void> deleteWorkout(int workoutId) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      await txn.delete('workout_sets', where: 'workoutId = ?', whereArgs: [workoutId]);
      await txn.delete('workouts', where: 'id = ?', whereArgs: [workoutId]);
    });
  }

  Future<void> deleteRoutine(int routineId) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      await txn.delete('routine_exercises', where: 'routineId = ?', whereArgs: [routineId]);
      await txn.delete('routines', where: 'id = ?', whereArgs: [routineId]);
    });
  }

  Future<void> createExercise(String name, String muscleGroup) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('exercises', {
      'name': name,
      'muscleGroup': muscleGroup,
    });
  }

  // Conta o número total de treinos finalizados
  Future<int> getTotalWorkouts() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM workouts WHERE isCompleted = 1');
    return (result.first['count'] as int?) ?? 0;
  }

  // Apaga apenas o histórico de treinos e séries concluídas
  Future<void> clearWorkoutHistory() async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      await txn.delete('workout_sets');
      await txn.delete('workouts');
    });
  }
}  //DatabaseRepository

final totalWorkoutsProvider = FutureProvider<int>((ref) async {
  final repo = DatabaseRepository();
  return await repo.getTotalWorkouts();
});

final totalVolumeProvider = FutureProvider<double>((ref) async {
  final repo = DatabaseRepository();
  return await repo.getTotalVolume();
});