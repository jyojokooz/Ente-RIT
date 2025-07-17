import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(
      'kampus_konnect_v2.db',
    ); // Use a new DB name to force recreation
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
        messageId TEXT UNIQUE NOT NULL, -- Unique ID for each message
        chatRoomId TEXT NOT NULL,
        senderId TEXT NOT NULL,
        text TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        deletedFor TEXT -- Will store the userId of the person who deleted it
      )
    ''');
  }

  Future<void> insertMessage(Map<String, dynamic> message) async {
    final db = await instance.database;
    await db.insert(
      'messages',
      message,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> markMessageAsDeletedFor(String messageId, String userId) async {
    final db = await instance.database;
    await db.update(
      'messages',
      {'deletedFor': userId},
      where: 'messageId = ?',
      whereArgs: [messageId],
    );
  }

  Future<List<Map<String, dynamic>>> getMessages(
    String chatRoomId,
    String currentUserId,
  ) async {
    final db = await instance.database;
    final result = await db.query(
      'messages',
      where: 'chatRoomId = ? AND (deletedFor IS NULL OR deletedFor != ?)',
      whereArgs: [chatRoomId, currentUserId],
      orderBy: 'timestamp DESC',
    );
    return result;
  }

  Future<void> deleteConversation(String chatRoomId) async {
    final db = await instance.database;
    await db.delete(
      'messages',
      where: 'chatRoomId = ?',
      whereArgs: [chatRoomId],
    );
  }
}
