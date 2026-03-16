import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:ayobami/core/constants/app_constants.dart';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Chat messages table
    await db.execute('''
      CREATE TABLE ${AppConstants.chatTable} (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        is_user INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        type INTEGER DEFAULT 0
      )
    ''');

    // User memory table
    await db.execute('''
      CREATE TABLE ${AppConstants.userMemoryTable} (
        id TEXT PRIMARY KEY,
        key TEXT NOT NULL UNIQUE,
        value TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Portfolio table
    await db.execute('''
      CREATE TABLE ${AppConstants.portfolioTable} (
        id TEXT PRIMARY KEY,
        symbol TEXT NOT NULL,
        name TEXT NOT NULL,
        quantity REAL NOT NULL,
        average_buy_price REAL NOT NULL,
        type INTEGER NOT NULL,
        added_at TEXT NOT NULL
      )
    ''');

    // Price alerts table
    await db.execute('''
      CREATE TABLE ${AppConstants.alertsTable} (
        id TEXT PRIMARY KEY,
        symbol TEXT NOT NULL,
        target_price REAL NOT NULL,
        type INTEGER NOT NULL,
        is_active INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Reminders table
    await db.execute('''
      CREATE TABLE ${AppConstants.remindersTable} (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        date_time TEXT NOT NULL,
        is_completed INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
