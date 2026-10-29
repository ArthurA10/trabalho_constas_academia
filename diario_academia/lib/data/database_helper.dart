import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('diario_academia.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Tabela de Exercícios (Atualizada com imagePath e isActive)
    await db.execute('''
      CREATE TABLE exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        muscleGroup TEXT NOT NULL,
        imagePath TEXT,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Tabela de Rotinas
    await db.execute('''
      CREATE TABLE routines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    // Relacionamento Rotina <-> Exercício
    await db.execute('''
      CREATE TABLE routine_exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        routineId INTEGER NOT NULL,
        exerciseId INTEGER NOT NULL,
        FOREIGN KEY (routineId) REFERENCES routines (id) ON DELETE CASCADE,
        FOREIGN KEY (exerciseId) REFERENCES exercises (id) ON DELETE CASCADE
      )
    ''');

    // Tabela de Treinos (Sessões)
    await db.execute('''
      CREATE TABLE workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT,
        isCompleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Tabela de Séries (Atualizada com exerciseNameSnapshot)
    await db.execute('''
      CREATE TABLE workout_sets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workoutId INTEGER NOT NULL,
        exerciseId INTEGER NOT NULL,
        exerciseNameSnapshot TEXT,
        weight REAL NOT NULL,
        reps INTEGER NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (workoutId) REFERENCES workouts (id) ON DELETE CASCADE,
        FOREIGN KEY (exerciseId) REFERENCES exercises (id) ON DELETE CASCADE
      )
    ''');

    await _seedExercises(db);
  }

  Future _seedExercises(Database db) async {
    // Dados iniciais atualizados (sem equipment e category)
    final initialExercises = [
      {'name': 'Supino Reto', 'muscleGroup': 'Peito', 'isActive': 1},
      {'name': 'Agachamento Livre', 'muscleGroup': 'Pernas', 'isActive': 1},
      {'name': 'Levantamento Terra', 'muscleGroup': 'Costas', 'isActive': 1},
      {'name': 'Leg Press', 'muscleGroup': 'Pernas', 'isActive': 1},
      {'name': 'Puxada Frontal', 'muscleGroup': 'Costas', 'isActive': 1},
      {'name': 'Rosca Direta', 'muscleGroup': 'Bíceps', 'isActive': 1},
      {'name': 'Tríceps na Polia', 'muscleGroup': 'Tríceps', 'isActive': 1},
    ];

    for (var ex in initialExercises) {
      await db.insert('exercises', ex);
    }
  }
}