import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/habit_data.dart';
import '../services/db_helper.dart';
import '../widgets/wave_painter.dart';
import '../widgets/streak_flame_painter.dart';

class DashboardScreen extends StatefulWidget {
  final UserProfileModel profile;
  final VoidCallback onProfileUpdated;

  const DashboardScreen({
    super.key,
    required this.profile,
    required this.onProfileUpdated,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final _dbHelper = DbHelper();
  late AnimationController _waveController;
  late AnimationController _flameController;

  DailyLogModel _todayLog = DailyLogModel(date: "");
  bool _isLoading = true;
  String _currentQuote =
      "Your future is created by what you do today, not tomorrow.";

  final List<String> _quotes = [
    "Your future is created by what you do today, not tomorrow.",
    "Small daily improvements over time lead to stunning results.",
    "Discipline is choosing between what you want now and what you want most.",
    "Do something today that your future self will thank you for.",
    "Success is the sum of small efforts, repeated day in and day out.",
    "The secret of your future is hidden in your daily routine.",
  ];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _flameController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _loadData();
    _currentQuote = _quotes[math.Random().nextInt(_quotes.length)];
  }

  @override
  void dispose() {
    _waveController.dispose();
    _flameController.dispose();
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

  Future<void> _addWater(int amount) async {
    setState(() {
      _todayLog.waterMl = math.min(
        _todayLog.waterMl + amount,
        3500,
      ); // Caps at 3.5 Liters
    });
    await _dbHelper.saveDailyLog(_todayLog);
    _awardXp(15, "Logged Water Intake!");
  }

  Future<void> _toggleSelfCare(String type, bool value) async {
    setState(() {
      if (type == 'shave') _todayLog.isShaved = value;
      if (type == 'hair') _todayLog.isHairCared = value;
      if (type == 'face') _todayLog.isFaceCared = value;
    });

    await _dbHelper.saveDailyLog(_todayLog);

    if (value) {
      _awardXp(25, "Completed Self Care Habit!");

      // Update streak profile if all 3 elements are finished
      if (_todayLog.isShaved &&
          _todayLog.isHairCared &&
          _todayLog.isFaceCared) {
        widget.profile.totalStreak += 1;
        widget.profile.lastActiveDate = DateTime.now();
        await _dbHelper.saveUserProfile(widget.profile);
        widget.onProfileUpdated();
        _awardXp(50, "Full Self-Care Streak Active!");
      }
    }
  }

  void _awardXp(int amount, String reason) {
    setState(() {
      widget.profile.addXp(amount, (newLevel) {
        // Trigger Level-Up popup
        _showLevelUpDialog(newLevel);
      });
    });
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
        backgroundColor: const Color(0xFF66FCF1).withValues(alpha: 0.9),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLevelUpDialog(int level) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F2833),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFFFD700), width: 2),
          ),
          title: const Center(
            child: Text(
              "LEVEL UP!",
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars, color: Color(0xFFFFD700), size: 80),
              const SizedBox(height: 15),
              Text(
                "You reached Level $level!",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Your Aura is growing stronger. Stay consistent and step up your life!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF66FCF1),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Keep Going",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0C10),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF66FCF1)),
        ),
      );
    }

    final double waterProgress = math.min(_todayLog.waterMl / 2000.0, 1.0);
    final int xpNeeded = widget.profile.xpNeededForNextLevel;
    final double xpProgress = math.min(
      widget.profile.currentXp / xpNeeded,
      1.0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gamified Level Header Card
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.flash_on,
                            color: Color(0xFFFFD700),
                            size: 20,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "RISE LEVEL ${widget.profile.currentLevel}",
                            style: const TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      // XP linear progress bar
                      Stack(
                        children: [
                          Container(
                            height: 6,
                            width: 180,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          Container(
                            height: 6,
                            width: 180 * xpProgress,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF66FCF1), Color(0xFF00FA9A)],
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "${widget.profile.currentXp} / $xpNeeded XP",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),

                  // Streak Flame widget
                  if (widget.profile.totalStreak > 0)
                    Row(
                      children: [
                        CustomPaint(
                          size: const Size(40, 40),
                          painter: StreakFlamePainter(
                            streak: widget.profile.totalStreak,
                            animationValue: _flameController.value,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "${widget.profile.totalStreak} Day Streak",
                          style: const TextStyle(
                            color: Color(0xFFFF7F50),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      "No Active Streak",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 25),

              // Welcome dashboard greetings
              const Text(
                "Rise Dashboard",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),

              // Motivation quotes card
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentQuote =
                        _quotes[math.Random().nextInt(_quotes.length)];
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2833).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.format_quote,
                        color: Color(0xFF66FCF1),
                        size: 24,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          _currentQuote,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // Row with Water Tracker (Left) and Self-Care Checklists (Right)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Water tracker Progress Circle
                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2833).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "Drink Water",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),
                          AnimatedBuilder(
                            animation: _waveController,
                            builder: (context, child) {
                              return Container(
                                height: 120,
                                width: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(
                                      0xFF66FCF1,
                                    ).withValues(alpha: 0.5),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF66FCF1,
                                      ).withValues(alpha: 0.15),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: CustomPaint(
                                  painter: WavePainter(
                                    progress: waterProgress,
                                    animationValue: _waveController.value,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 15),
                          Text(
                            "${_todayLog.waterMl} / 2000 ml",
                            style: const TextStyle(
                              color: Color(0xFF66FCF1),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(
                                    0xFF66FCF1,
                                  ).withValues(alpha: 0.2),
                                  foregroundColor: const Color(0xFF66FCF1),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () => _addWater(250),
                                child: const Text(
                                  "+250ml",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(
                                    0xFF66FCF1,
                                  ).withValues(alpha: 0.2),
                                  foregroundColor: const Color(0xFF66FCF1),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () => _addWater(500),
                                child: const Text(
                                  "+500ml",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),

                  // Self Care checklist (Right)
                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2833).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Body Care",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),
                          _buildSelfCareTile(
                            "Shave",
                            _todayLog.isShaved,
                            (val) => _toggleSelfCare('shave', val),
                          ),
                          _buildSelfCareTile(
                            "Hair Care",
                            _todayLog.isHairCared,
                            (val) => _toggleSelfCare('hair', val),
                          ),
                          _buildSelfCareTile(
                            "Facecare",
                            _todayLog.isFaceCared,
                            (val) => _toggleSelfCare('face', val),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 90), // Space for navigation bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelfCareTile(
    String title,
    bool isCompleted,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isCompleted
            ? const Color(0xFF00FA9A).withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF00FA9A).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.03),
        ),
      ),
      child: CheckboxListTile(
        title: Text(
          title,
          style: TextStyle(
            color: isCompleted ? Colors.white70 : Colors.white,
            fontSize: 12,
          ),
        ),
        value: isCompleted,
        onChanged: (val) => onChanged(val ?? false),
        activeColor: const Color(0xFF00FA9A),
        checkColor: Colors.black,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      ),
    );
  }
}
