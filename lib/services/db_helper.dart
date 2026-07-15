import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/habit_data.dart';

class DbHelper {
  static final DbHelper _instance = DbHelper._internal();
  static Database? _database;

  factory DbHelper() => _instance;

  DbHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final pathString = join(dbPath, 'aura_habit.db');

    return await openDatabase(
      pathString,
      version: 1,
      onCreate: (db, version) async {
        // Create user_profile table
        await db.execute('''
          CREATE TABLE user_profile (
            id INTEGER PRIMARY KEY,
            current_level INTEGER,
            current_xp INTEGER,
            total_streak INTEGER,
            last_active_date TEXT,
            sleep_target_time TEXT,
            screen_time_limit INTEGER,
            hard_truth_mode INTEGER
          )
        ''');

        // Insert initial single profile row
        await db.insert('user_profile', {
          'id': 1,
          'current_level': 1,
          'current_xp': 0,
          'total_streak': 0,
          'last_active_date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'sleep_target_time': '22:30',
          'screen_time_limit': 120,
          'hard_truth_mode': 1,
        });

        // Create wishes table
        await db.execute('''
          CREATE TABLE wishes (
            id TEXT PRIMARY KEY,
            title TEXT,
            description TEXT,
            created_at TEXT
          )
        ''');

        // Create goals table (linked to wishes optionally)
        await db.execute('''
          CREATE TABLE goals (
            id TEXT PRIMARY KEY,
            title TEXT,
            type TEXT,
            is_completed INTEGER,
            created_at TEXT,
            wish_id TEXT,
            FOREIGN KEY (wish_id) REFERENCES wishes (id) ON DELETE CASCADE
          )
        ''');

        // Create daily_logs table
        await db.execute('''
          CREATE TABLE daily_logs (
            date TEXT PRIMARY KEY,
            water_ml INTEGER,
            is_shaved INTEGER,
            is_hair_cared INTEGER,
            is_face_cared INTEGER,
            exercise_seconds INTEGER,
            reading_seconds INTEGER,
            screen_time_minutes INTEGER
          )
        ''');
      },
    );
  }

  // --- USER PROFILE CRUD ---
  Future<UserProfileModel> getUserProfile() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('user_profile', where: 'id = 1');
    if (maps.isNotEmpty) {
      return UserProfileModel.fromMap(maps.first);
    }
    return UserProfileModel();
  }

  Future<void> saveUserProfile(UserProfileModel profile) async {
    final db = await database;
    await db.update(
      'user_profile',
      profile.toMap(),
      where: 'id = 1',
    );
  }

  // --- WISHES CRUD ---
  Future<List<WishModel>> getWishes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('wishes', orderBy: 'created_at DESC');
    return List.generate(maps.length, (i) => WishModel.fromMap(maps[i]));
  }

  Future<void> insertWish(WishModel wish) async {
    final db = await database;
    await db.insert('wishes', wish.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteWish(String id) async {
    final db = await database;
    // Delete cascading goals linked to this wish
    await db.delete('goals', where: 'wish_id = ?', whereArgs: [id]);
    await db.delete('wishes', where: 'id = ?', whereArgs: [id]);
  }

  // --- GOALS CRUD ---
  Future<List<GoalModel>> getGoals() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('goals', orderBy: 'created_at ASC');
    return List.generate(maps.length, (i) => GoalModel.fromMap(maps[i]));
  }

  Future<void> insertGoal(GoalModel goal) async {
    final db = await database;
    await db.insert('goals', goal.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateGoalStatus(String id, bool isCompleted) async {
    final db = await database;
    await db.update(
      'goals',
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteGoal(String id) async {
    final db = await database;
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  // --- DAILY LOGS CRUD ---
  Future<DailyLogModel> getDailyLog(String dateStr) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_logs',
      where: 'date = ?',
      whereArgs: [dateStr],
    );

    if (maps.isNotEmpty) {
      return DailyLogModel.fromMap(maps.first);
    }

    // Auto-create a log for the date if not exists
    final newLog = DailyLogModel(date: dateStr);
    await db.insert('daily_logs', newLog.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
    return newLog;
  }

  Future<void> saveDailyLog(DailyLogModel log) async {
    final db = await database;
    await db.insert(
      'daily_logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get historical logs for success analytics (e.g. past 7 days)
  Future<List<DailyLogModel>> getHistoricalLogs(int daysLimit) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_logs',
      orderBy: 'date DESC',
      limit: daysLimit,
    );
    // Reverse it to be chronological (oldest to newest)
    final logs = List.generate(maps.length, (i) => DailyLogModel.fromMap(maps[i]));
    return logs.reversed.toList();
  }
}
