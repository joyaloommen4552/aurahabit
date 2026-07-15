class WishModel {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;

  WishModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'created_at': createdAt.toIso8601String(),
      };

  factory WishModel.fromMap(Map<String, dynamic> map) => WishModel(
        id: map['id'],
        title: map['title'],
        description: map['description'] ?? '',
        createdAt: DateTime.parse(map['created_at']),
      );
}

class GoalModel {
  final String id;
  final String title;
  final String type; // 'daily', 'weekly', 'monthly', 'yearEnd'
  bool isCompleted;
  final DateTime createdAt;
  final String? wishId; // Optional link to a parent wish

  GoalModel({
    required this.id,
    required this.title,
    required this.type,
    this.isCompleted = false,
    required this.createdAt,
    this.wishId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'type': type,
        'is_completed': isCompleted ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
        'wish_id': wishId,
      };

  factory GoalModel.fromMap(Map<String, dynamic> map) => GoalModel(
        id: map['id'],
        title: map['title'],
        type: map['type'],
        isCompleted: (map['is_completed'] ?? 0) == 1,
        createdAt: DateTime.parse(map['created_at']),
        wishId: map['wish_id'],
      );
}

class DailyLogModel {
  final String date; // YYYY-MM-DD
  int waterMl;
  bool isShaved;
  bool isHairCared;
  bool isFaceCared;
  int exerciseSeconds;
  int readingSeconds;
  int screenTimeMinutes;

  DailyLogModel({
    required this.date,
    this.waterMl = 0,
    this.isShaved = false,
    this.isHairCared = false,
    this.isFaceCared = false,
    this.exerciseSeconds = 0,
    this.readingSeconds = 0,
    this.screenTimeMinutes = 0,
  });

  Map<String, dynamic> toMap() => {
        'date': date,
        'water_ml': waterMl,
        'is_shaved': isShaved ? 1 : 0,
        'is_hair_cared': isHairCared ? 1 : 0,
        'is_face_cared': isFaceCared ? 1 : 0,
        'exercise_seconds': exerciseSeconds,
        'reading_seconds': readingSeconds,
        'screen_time_minutes': screenTimeMinutes,
      };

  factory DailyLogModel.fromMap(Map<String, dynamic> map) => DailyLogModel(
        date: map['date'],
        waterMl: map['water_ml'] ?? 0,
        isShaved: (map['is_shaved'] ?? 0) == 1,
        isHairCared: (map['is_hair_cared'] ?? 0) == 1,
        isFaceCared: (map['is_face_cared'] ?? 0) == 1,
        exerciseSeconds: map['exercise_seconds'] ?? 0,
        readingSeconds: map['reading_seconds'] ?? 0,
        screenTimeMinutes: map['screen_time_minutes'] ?? 0,
      );
}

class UserProfileModel {
  int currentLevel;
  int currentXp;
  int totalStreak;
  DateTime lastActiveDate;
  String sleepTargetTime; // "HH:MM" format
  int screenTimeLimit; // in minutes
  bool hardTruthMode;

  UserProfileModel({
    this.currentLevel = 1,
    this.currentXp = 0,
    this.totalStreak = 0,
    DateTime? lastActiveDate,
    this.sleepTargetTime = "22:30",
    this.screenTimeLimit = 120, // 2 hours
    this.hardTruthMode = true,
  }) : lastActiveDate = lastActiveDate ?? DateTime.now().subtract(const Duration(days: 1));

  int get xpNeededForNextLevel => currentLevel * 150;

  void addXp(int amount, void Function(int newLevel) onLevelUp) {
    currentXp += amount;
    while (currentXp >= xpNeededForNextLevel) {
      currentXp -= xpNeededForNextLevel;
      currentLevel += 1;
      onLevelUp(currentLevel);
    }
  }

  Map<String, dynamic> toMap() => {
        'id': 1, // Single row profile record
        'current_level': currentLevel,
        'current_xp': currentXp,
        'total_streak': totalStreak,
        'last_active_date': lastActiveDate.toIso8601String(),
        'sleep_target_time': sleepTargetTime,
        'screen_time_limit': screenTimeLimit,
        'hard_truth_mode': hardTruthMode ? 1 : 0,
      };

  factory UserProfileModel.fromMap(Map<String, dynamic> map) => UserProfileModel(
        currentLevel: map['current_level'] ?? 1,
        currentXp: map['current_xp'] ?? 0,
        totalStreak: map['total_streak'] ?? 0,
        lastActiveDate: map['last_active_date'] != null
            ? DateTime.parse(map['last_active_date'])
            : null,
        sleepTargetTime: map['sleep_target_time'] ?? "22:30",
        screenTimeLimit: map['screen_time_limit'] ?? 120,
        hardTruthMode: (map['hard_truth_mode'] ?? 1) == 1,
      );
}
