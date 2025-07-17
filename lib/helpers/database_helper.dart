import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kampus_konnect.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chatRoomId TEXT NOT NULL,
        senderId TEXT NOT NULL,
        text TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');
  }

  Future<void> insertMessage(Map<String, dynamic> message) async {
    final db = await instance.database;
    await db.insert('messages', message);
  }

  Future<List<Map<String, dynamic>>> getMessages(String chatRoomId) async {
    final db = await instance.database;
    final result = await db.query(
      'messages',
      where: 'chatRoomId = ?',
      whereArgs: [chatRoomId],
      orderBy: 'timestamp DESC',
    );
    return result;
  }
}
