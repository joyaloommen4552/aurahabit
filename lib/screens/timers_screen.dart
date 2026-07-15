import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/habit_data.dart';
import '../services/db_helper.dart';

class TimersScreen extends StatefulWidget {
  final UserProfileModel profile;
  final VoidCallback onProfileUpdated;

  const TimersScreen({
    super.key,
    required this.profile,
    required this.onProfileUpdated,
  });

  @override
  State<TimersScreen> createState() => _TimersScreenState();
}

class _TimersScreenState extends State<TimersScreen> {
  final _dbHelper = DbHelper();
  DailyLogModel _todayLog = DailyLogModel(date: "");
  bool _isLoading = true;

  // Exercise Timer States
  Timer? _exerciseTimer;
  bool _isExerciseRunning = false;
  final int _exerciseDuration = 1800; // 30 minutes target default

  // Reading Timer States
  Timer? _readingTimer;
  bool _isReadingRunning = false;
  final int _readingDuration = 1800; // 30 minutes target default

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _exerciseTimer?.cancel();
    _readingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final log = await _dbHelper.getDailyLog(todayStr);

    setState(() {
      _todayLog = log;
      _isLoading = false;
    });
  }

  // --- EXERCISE TIMER LOGIC ---
  void _toggleExercise() {
    if (_isExerciseRunning) {
      _exerciseTimer?.cancel();
      setState(() {
        _isExerciseRunning = false;
      });
    } else {
      setState(() {
        _isExerciseRunning = true;
      });
      _exerciseTimer = Timer.periodic(const Duration(seconds: 1), (
        timer,
      ) async {
        setState(() {
          _todayLog.exerciseSeconds += 1;
        });

        // Save log every 10 seconds to database for durability
        if (_todayLog.exerciseSeconds % 10 == 0) {
          await _dbHelper.saveDailyLog(_todayLog);
        }

        // Target reached
        if (_todayLog.exerciseSeconds >= _exerciseDuration) {
          _exerciseTimer?.cancel();
          setState(() {
            _isExerciseRunning = false;
          });
          await _dbHelper.saveDailyLog(_todayLog);
          _awardXp(50, "Exercise Session Target Reached!");
          _triggerAlarm(
            "Exercise finished! Fantastic job stepping up your health!",
          );
        }
      });
    }
  }

  void _resetExercise() async {
    _exerciseTimer?.cancel();
    setState(() {
      _isExerciseRunning = false;
      _todayLog.exerciseSeconds = 0;
    });
    await _dbHelper.saveDailyLog(_todayLog);
  }

  // --- READING TIMER LOGIC ---
  void _toggleReading() {
    if (_isReadingRunning) {
      _readingTimer?.cancel();
      setState(() {
        _isReadingRunning = false;
      });
    } else {
      setState(() {
        _isReadingRunning = true;
      });
      _readingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        setState(() {
          _todayLog.readingSeconds += 1;
        });

        if (_todayLog.readingSeconds % 10 == 0) {
          await _dbHelper.saveDailyLog(_todayLog);
        }

        if (_todayLog.readingSeconds >= _readingDuration) {
          _readingTimer?.cancel();
          setState(() {
            _isReadingRunning = false;
          });
          await _dbHelper.saveDailyLog(_todayLog);
          _awardXp(50, "Reading Session Target Reached!");
          _triggerAlarm("Reading finished! Keep sharpening your mind!");
        }
      });
    }
  }

  void _resetReading() async {
    _readingTimer?.cancel();
    setState(() {
      _isReadingRunning = false;
      _todayLog.readingSeconds = 0;
    });
    await _dbHelper.saveDailyLog(_todayLog);
  }

  void _awardXp(int amount, String reason) {
    widget.profile.addXp(amount, (newLevel) {});
    _dbHelper.saveUserProfile(widget.profile);
    widget.onProfileUpdated();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "+$amount XP: $reason",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFFF7F50),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _triggerAlarm(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2833),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFF7F50), width: 1.5),
        ),
        title: Row(
          children: const [
            Icon(Icons.alarm_on, color: Color(0xFFFF7F50)),
            SizedBox(width: 10),
            Text("Focus Target Met!", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Done",
              style: TextStyle(
                color: Color(0xFFFF7F50),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0C10),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF7F50)),
        ),
      );
    }

    final double exerciseProgress =
        _todayLog.exerciseSeconds / _exerciseDuration;
    final double readingProgress = _todayLog.readingSeconds / _readingDuration;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      appBar: AppBar(
        title: const Text(
          "Focus Space",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Screen time monitor header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2833).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.phone_android,
                    color: Color(0xFFFF7F50),
                    size: 28,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Today's Screen Time Usage",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "${_todayLog.screenTimeMinutes} mins used / ${widget.profile.screenTimeLimit} min limit",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(
                        0xFFFF7F50,
                      ).withValues(alpha: .1),
                      foregroundColor: const Color(0xFFFF7F50),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: () async {
                      // Manual screen time addition for testing
                      setState(() {
                        _todayLog.screenTimeMinutes += 15;
                      });
                      await _dbHelper.saveDailyLog(_todayLog);
                    },
                    child: const Text(
                      "+15 min",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Exercise Timer Section
            _buildTimerCard(
              title: "Exercise Timer",
              progress: exerciseProgress,
              timeStr: _formatTime(_todayLog.exerciseSeconds),
              isRunning: _isExerciseRunning,
              onToggle: _toggleExercise,
              onReset: _resetExercise,
              accentColor: const Color(0xFFFF7F50),
            ),
            const SizedBox(height: 25),

            // Reading Timer Section
            _buildTimerCard(
              title: "Book Reading Timer",
              progress: readingProgress,
              timeStr: _formatTime(_todayLog.readingSeconds),
              isRunning: _isReadingRunning,
              onToggle: _toggleReading,
              onReset: _resetReading,
              accentColor: const Color(0xFF66FCF1),
            ),
            const SizedBox(height: 90), // Navigation bar safety margin
          ],
        ),
      ),
    );
  }

  Widget _buildTimerCard({
    required String title,
    required double progress,
    required String timeStr,
    required bool isRunning,
    required VoidCallback onToggle,
    required VoidCallback onReset,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2833).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Circle Countdown Progress Ring
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 140,
                width: 140,
                child: CircularProgressIndicator(
                  value: math.min(progress, 1.0),
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  color: accentColor,
                  strokeWidth: 8,
                ),
              ),
              Column(
                children: [
                  Text(
                    timeStr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    "Target: 30:00",
                    style: TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.refresh,
                  color: Colors.white54,
                  size: 24,
                ),
                onPressed: onReset,
              ),
              const SizedBox(width: 25),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: onToggle,
                icon: Icon(isRunning ? Icons.pause : Icons.play_arrow),
                label: Text(
                  isRunning ? "Pause" : "Start Focus",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
