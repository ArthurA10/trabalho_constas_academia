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
    // Tabela de Exercícios
    await db.execute('''
      CREATE TABLE exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        muscleGroup TEXT NOT NULL,
        equipment TEXT NOT NULL,
        category TEXT NOT NULL
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

    // Tabela de Séries
    await db.execute('''
      CREATE TABLE workout_sets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workoutId INTEGER NOT NULL,
        exerciseId INTEGER NOT NULL,
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
    final initialExercises = [
      {'name': 'Supino Reto', 'muscleGroup': 'Peito', 'equipment': 'Barra', 'category': 'Musculação'},
      {'name': 'Agachamento Livre', 'muscleGroup': 'Pernas', 'equipment': 'Barra', 'category': 'Musculação'},
      {'name': 'Levantamento Terra', 'muscleGroup': 'Costas', 'equipment': 'Barra', 'category': 'Musculação'},
      {'name': 'Leg Press', 'muscleGroup': 'Pernas', 'equipment': 'Máquina', 'category': 'Musculação'},
      {'name': 'Puxada Frontal', 'muscleGroup': 'Costas', 'equipment': 'Cabo', 'category': 'Musculação'},
      {'name': 'Rosca Direta', 'muscleGroup': 'Bíceps', 'equipment': 'Halteres', 'category': 'Musculação'},
      {'name': 'Tríceps na Polia', 'muscleGroup': 'Tríceps', 'equipment': 'Cabo', 'category': 'Musculação'},
    ];

    for (var ex in initialExercises) {
      await db.insert('exercises', ex);
    }
  }
}