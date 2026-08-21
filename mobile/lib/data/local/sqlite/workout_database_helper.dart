import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:core_shared/models/exercise_model.dart';
import 'package:core_shared/models/workout_plan_model.dart';

class WorkoutDatabaseHelper {
  static final WorkoutDatabaseHelper instance = WorkoutDatabaseHelper._init();
  static Database? _database;

  WorkoutDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('workout_cache.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Table for Exercises (Nearly 1000 items)
    await db.execute('''
      CREATE TABLE exercises (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        code TEXT NOT NULL,
        difficulty TEXT,
        bodyPartId TEXT,
        categoryId TEXT,
        targetMuscleId TEXT,
        rawJson TEXT NOT NULL
      )
    ''');

    // 2. Table for Workout Plans
    await db.execute('''
      CREATE TABLE workout_plans (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        goal TEXT,
        difficulty TEXT,
        rawJson TEXT NOT NULL
      )
    ''');

    // Create indexes for high-speed offline searching
    await db.execute('CREATE INDEX idx_exercises_name ON exercises(name)');
    await db.execute('CREATE INDEX idx_exercises_bodypart ON exercises(bodyPartId)');
    await db.execute('CREATE INDEX idx_exercises_difficulty ON exercises(difficulty)');
    await db.execute('CREATE INDEX idx_exercises_category ON exercises(categoryId)');
    await db.execute('CREATE INDEX idx_plans_goal ON workout_plans(goal)');
  }

  // Insert exercises in batches (Optimized for 1000+ records)
  Future<void> insertExercises(List<ExerciseModel> exercisesList) async {
    final db = await database;
    final batch = db.batch();

    for (final ex in exercisesList) {
      batch.insert(
        'exercises',
        {
          'id': ex.id,
          'name': ex.name,
          'code': ex.code,
          'difficulty': ex.difficulty ?? '',
          'bodyPartId': ex.bodyPart?.id ?? '',
          'categoryId': ex.category?.id ?? '',
          'targetMuscleId': ex.targetMuscle?.id ?? '',
          'rawJson': jsonEncode(ex.toJson()),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  // Insert plans
  Future<void> insertPlans(List<WorkoutPlanModel> plansList) async {
    final db = await database;
    final batch = db.batch();

    for (final plan in plansList) {
      batch.insert(
        'workout_plans',
        {
          'id': plan.id,
          'name': plan.title,
          'goal': plan.goal,
          'difficulty': plan.difficulty,
          'rawJson': jsonEncode(plan.toJson()),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  // Search exercises with filter and paging
  Future<List<ExerciseModel>> searchExercisesOffline(
    String query, {
    String? bodyPartId,
    String? categoryId,
    String? difficulty,
    int limit = 20,
    int offset = 0,
  }) async {
    final db = await database;

    String whereClause = '';
    final List<dynamic> whereArgs = [];

    if (query.isNotEmpty) {
      whereClause += 'name LIKE ?';
      whereArgs.add('%$query%');
    }

    if (bodyPartId != null && bodyPartId.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'bodyPartId = ?';
      whereArgs.add(bodyPartId);
    }

    if (categoryId != null && categoryId.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'categoryId = ?';
      whereArgs.add(categoryId);
    }

    if (difficulty != null && difficulty.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'difficulty = ?';
      whereArgs.add(difficulty);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'exercises',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      limit: limit,
      offset: offset,
      orderBy: 'name ASC',
    );

    return maps.map((map) {
      final jsonStr = map['rawJson'] as String;
      return ExerciseModel.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    }).toList();
  }

  // Get plans offline
  Future<List<WorkoutPlanModel>> getPlansOffline({String? goal}) async {
    final db = await database;
    String? whereClause;
    List<dynamic>? whereArgs;

    if (goal != null && goal.isNotEmpty) {
      whereClause = 'goal = ?';
      whereArgs = [goal];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'workout_plans',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );

    return maps.map((map) {
      final jsonStr = map['rawJson'] as String;
      return WorkoutPlanModel.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    }).toList();
  }

  // Clear cached data
  Future<void> clearCache() async {
    final db = await database;
    await db.delete('exercises');
    await db.delete('workout_plans');
  }
}
