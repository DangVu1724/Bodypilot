import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:core_shared/models/food_model.dart';
import 'package:core_shared/models/food_category_model.dart';

/// Quản lý cơ sở dữ liệu SQLite cục bộ cho món ăn
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
    // Bảng danh mục món ăn
    await db.execute('''
      CREATE TABLE food_categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        rawJson TEXT NOT NULL
      )
    ''');

    // Bảng món ăn
    await db.execute('''
      CREATE TABLE foods (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        categoryId TEXT,
        rawJson TEXT NOT NULL
      )
    ''');

    // Tạo chỉ mục giúp tìm kiếm nhanh
    await db.execute('CREATE INDEX idx_foods_name ON foods(name)');
    await db.execute('CREATE INDEX idx_foods_category ON foods(categoryId)');
    await db.execute('CREATE INDEX idx_foods_type ON foods(type)');
    await db.execute('CREATE INDEX idx_categories_name ON food_categories(name)');
  }

  /// Thêm danh sách món ăn vào SQLite theo lô 1,000 món/lần
  Future<void> insertFoods(List<FoodModel> foodsList) async {
    final db = await database;
    const chunkSize = 1000;

    for (var i = 0; i < foodsList.length; i += chunkSize) {
      final end = (i + chunkSize < foodsList.length) ? i + chunkSize : foodsList.length;
      final chunk = foodsList.sublist(i, end);
      final batch = db.batch();

      for (final food in chunk) {
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
  }

  /// Thêm danh mục món ăn vào SQLite
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

  /// Tìm kiếm món ăn ngoại tuyến trong SQLite
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
    } else if (type != null && type.isNotEmpty) {
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

  /// Lấy danh mục món ăn ngoại tuyến
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

  /// Xóa dữ liệu bộ nhớ tạm SQLite
  Future<void> clearCache() async {
    final db = await database;
    await db.delete('foods');
    await db.delete('food_categories');
  }
}
