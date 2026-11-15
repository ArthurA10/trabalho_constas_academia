import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:io';

import 'models.dart';

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

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // Tabela de Exercícios (Atualizada com imagePath e isActive)
    await db.execute('''
      CREATE TABLE exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        muscleGroup TEXT NOT NULL,
        imagePath TEXT,
        isActive INTEGER NOT NULL DEFAULT 1,
        category TEXT DEFAULT 'musculacao'
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
        routine_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        FOREIGN KEY (routine_id) REFERENCES routines (id) ON DELETE CASCADE,
        FOREIGN KEY (exercise_id) REFERENCES exercises (id) ON DELETE CASCADE
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

    await db.execute('''
  CREATE TABLE body_weight (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    weight REAL,
    date TEXT
  )
''');

    await _seedExercises(db);
  }

  Future _seedExercises(Database db) async {
    // Dados iniciais atualizados (sem equipment e category)
    final initialExercises = [
      {
        'name': 'Supino Reto',
        'muscleGroup': 'Peito',
        'imagePath': 'assets/gifs/supino_reto.gif',
        'isActive': 1,
      },
      {
        'name': 'Supino Inclinado com Halteres',
        'muscleGroup': 'Peito',
        'imagePath': 'assets/gifs/supino_inclinado.gif',
        'isActive': 1,
      },
      {
        'name': 'Crossover Polia Alta',
        'muscleGroup': 'Peito',
        'imagePath': 'assets/gifs/crucifixo_crossover_alto.gif',
        'isActive': 1,
      },
      {
        'name': 'Agachamento Livre',
        'muscleGroup': 'Pernas',
        'imagePath': 'assets/gifs/agachamento_livre.gif',
        'isActive': 1,
      },
      {
        'name': 'Levantamento Terra',
        'muscleGroup': 'Costas',
        'imagePath': 'assets/gifs/terra.gif',
        'isActive': 1,
      },
      {
        'name': 'Leg Press',
        'muscleGroup': 'Quadríceps',
        'imagePath': 'assets/gifs/legpress.gif',
        'isActive': 1,
      },
      {
        'name': 'Puxada Frontal',
        'muscleGroup': 'Costas',
        'imagePath': 'assets/gifs/puxada.gif',
        'isActive': 1,
      },
      {
        'name': 'Rosca Direta com Barra',
        'muscleGroup': 'Bíceps',
        'imagePath': 'assets/gifs/rosca_direta.gif',
        'isActive': 1,
      },
      {
        'name': 'Tríceps Pulley',
        'muscleGroup': 'Tríceps',
        'imagePath': 'assets/gifs/pulley.gif',
        'isActive': 1,
      },
      {
        'name': 'Tríceps Francês com Halteres',
        'muscleGroup': 'Tríceps',
        'imagePath': 'assets/gifs/triceps_frances.gif',
        'isActive': 1,
      },
      {
        'name': 'Mesa Flexora',
        'muscleGroup': 'Posterior de Coxa',
        'imagePath': 'assets/gifs/flexora.gif',
        'isActive': 1,
      },
      {
        'name': 'Stiff',
        'muscleGroup': 'Posterior de Coxa',
        'imagePath': 'assets/gifs/stiff.gif',
        'isActive': 1,
      },
      {
        'name': 'Panturrilha em Pé Máquina',
        'muscleGroup': 'Panturrilha',
        'imagePath': 'assets/gifs/panturrilha_pe.gif',
        'isActive': 1,
      },
      {
        'name': 'Remada Articulada',
        'muscleGroup': 'Costas',
        'imagePath': 'assets/gifs/remada_articulada.gif',
        'isActive': 1,
      },
      {
        'name': 'Remada Baixa',
        'muscleGroup': 'Costas',
        'imagePath': 'assets/gifs/remada_baixa.gif',
        'isActive': 1,
      },
      {
        'name': 'Rosca Scott',
        'muscleGroup': 'Bíceps',
        'imagePath': 'assets/gifs/scott.gif',
        'isActive': 1,
      },
      {
        'name': 'Elevação Lateral com Halteres',
        'muscleGroup': 'Ombro',
        'imagePath': 'assets/gifs/elevacao_lateral.gif',
        'isActive': 1,
      },
      {
        'name': 'Desenvolvimento Ombro Máquina',
        'muscleGroup': 'Ombro',
        'imagePath': 'assets/gifs/desenvolvimento_ombro.gif',
        'isActive': 1,
      },
    ];

    for (var ex in initialExercises) {
      await db.insert('exercises', ex);
    }
  }

  Future<int> addExercise(Exercise exercise) async {
    final db = await instance.database;
    return await db.insert('exercises', exercise.toMap());
  }

  // Obtém apenas os exercícios ativos (exclui os apagados)
  Future<List<Exercise>> getActiveExercises() async {
    final db = await instance.database;
    final maps = await db.query(
      'exercises',
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'name ASC', // Opcional: ordena por ordem alfabética
    );
    return maps.map((e) => Exercise.fromMap(e)).toList();
  }

  // Faz a "Eliminação Segura" (Soft Delete) em vez de apagar definitivamente
  Future<int> deactivateExercise(int id) async {
    final db = await instance.database;
    return await db.update(
      'exercises',
      {'isActive': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertBodyWeight(double weight) async {
    final db = await instance.database;
    return await db.insert('body_weight', {
      'weight': weight,
      'date': DateTime.now().toIso8601String(),
    });
  }

  Future<List> getBodyWeights() async {
    final db = await instance.database;
    return await db.query('body_weight', orderBy: 'date ASC');
  }

  Future<void> updateRoutineExercises(int routineId, List<int> exerciseIds) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      // Deleta os exercícios antigos vinculados a esta rotina
      await txn.delete('routine_exercises', where: 'routine_id = ?', whereArgs: [routineId]);
      
      // Insere a nova lista de exercícios
      for (int id in exerciseIds) {
        await txn.insert('routine_exercises', {
          'routine_id': routineId,
          'exercise_id': id,
        });
      }
    });
  }

  Future<List> getVolumeData() async {
  final db = await DatabaseHelper.instance.database; // Ajuste para a sua instância do banco
  
  // Calcula a soma de (peso * repetições) dos exercícios completados, agrupado por dia
  return await db.rawQuery('''
    SELECT 
      date(w.startTime) as date, 
      SUM(ws.weight * ws.reps) as total_volume
    FROM workouts w
    INNER JOIN workout_sets ws ON w.id = ws.workoutId
    WHERE ws.isCompleted = 1
    GROUP BY date(w.startTime)
    ORDER BY date(w.startTime) ASC
  ''');
}
}