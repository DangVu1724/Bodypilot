import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:core_shared/models/food_model.dart';
import 'package:core_shared/models/food_category_model.dart';

class FoodDatabaseHelper {
  static final FoodDatabaseHelper instance = FoodDatabaseHelper._init();
  static Database? _database;

  FoodDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('food_cache.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Table for categories
    await db.execute('''
      CREATE TABLE food_categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        rawJson TEXT NOT NULL
      )
    ''');

    // 2. Table for foods
    await db.execute('''
      CREATE TABLE foods (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        categoryId TEXT,
        rawJson TEXT NOT NULL
      )
    ''');

    // Create indexes for high-speed offline searching
    await db.execute('CREATE INDEX idx_foods_name ON foods(name)');
    await db.execute('CREATE INDEX idx_foods_category ON foods(categoryId)');
    await db.execute('CREATE INDEX idx_foods_type ON foods(type)');
    await db.execute('CREATE INDEX idx_categories_name ON food_categories(name)');
  }

  // Insert foods in batches (Optimized for multiple records)
  Future<void> insertFoods(List<FoodModel> foodsList) async {
    final db = await database;
    final batch = db.batch();
    
    for (final food in foodsList) {
      batch.insert(
        'foods',
        {
          'id': food.id,
          'name': food.name,
          'type': food.type,
          'categoryId': food.category?.id ?? '',
          'rawJson': jsonEncode(food.toJson()),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  // Insert categories
  Future<void> insertCategories(List<FoodCategoryModel> categoriesList) async {
    final db = await database;
    final batch = db.batch();
    
    for (final cat in categoriesList) {
      batch.insert(
        'food_categories',
        {
          'id': cat.id,
          'name': cat.name,
          'rawJson': jsonEncode(cat.toJson()),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  // Search foods with filter and paging
  Future<List<FoodModel>> searchFoodsOffline(
    String query, {
    String? categoryId,
    String? type,
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await database;
    
    String whereClause = '';
    final List<dynamic> whereArgs = [];
    
    if (query.isNotEmpty) {
      whereClause += 'name LIKE ?';
      whereArgs.add('%$query%');
    }
    
    if (categoryId != null && categoryId.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'categoryId = ?';
      whereArgs.add(categoryId);
    }

    if (type != null && type.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += '(type = ? OR type = "BOTH")';
      whereArgs.add(type);
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      'foods',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      limit: limit,
      offset: offset,
      orderBy: 'name ASC',
    );
    
    return maps.map((map) {
      final jsonStr = map['rawJson'] as String;
      return FoodModel.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    }).toList();
  }

  // Get categories offline
  Future<List<FoodCategoryModel>> getCategoriesOffline() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'food_categories',
      orderBy: 'name ASC',
    );
    
    return maps.map((map) {
      final jsonStr = map['rawJson'] as String;
      return FoodCategoryModel.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    }).toList();
  }

  // Clear cached data
  Future<void> clearCache() async {
    final db = await database;
    await db.delete('foods');
    await db.delete('food_categories');
  }
}
