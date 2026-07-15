import 'dart:async';
import 'package:flutter/material.dart';
import 'models/habit_data.dart';
import 'services/db_helper.dart';
import 'screens/dashboard_screen.dart';
import 'screens/timers_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/wish_vault_screen.dart';
import 'screens/sleep_calculator_screen.dart';
import 'widgets/custom_nav_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AuraHabitApp());
}

class AuraHabitApp extends StatelessWidget {
  const AuraHabitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rise',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF66FCF1),
        scaffoldBackgroundColor: const Color(0xFF0B0C10),
        fontFamily: 'Roboto',
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  final _dbHelper = DbHelper();
  int _selectedIndex = 0;
  UserProfileModel _profile = UserProfileModel();
  DailyLogModel _todayLog = DailyLogModel(date: "");
  bool _isLoading = true;

  // Screen time tracking timer
  Timer? _screenTimeTimer;
  bool _showHardTruthBlocker = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadProfileAndLogs();

    // Start 1-minute check loop for screen time and bedtime limit checks
    _screenTimeTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted && !_isLoading) {
        _incrementScreenTime();
        _checkHardTruthAlerts();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _screenTimeTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadProfileAndLogs();
    }
  }

  Future<void> _loadProfileAndLogs() async {
    final profile = await _dbHelper.getUserProfile();
    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final log = await _dbHelper.getDailyLog(todayStr);

    setState(() {
      _profile = profile;
      _todayLog = log;
      _isLoading = false;
    });

    _checkHardTruthAlerts();
  }

  void _incrementScreenTime() async {
    setState(() {
      _todayLog.screenTimeMinutes += 1;
    });
    await _dbHelper.saveDailyLog(_todayLog);
  }

  void _checkHardTruthAlerts() {
    if (!_profile.hardTruthMode) {
      setState(() {
        _showHardTruthBlocker = false;
      });
      return;
    }

    final now = DateTime.now();

    // Check 1: Bedtime boundary crossed
    bool isPastBedtime = false;
    final sleepParts = _profile.sleepTargetTime.split(':');
    if (sleepParts.length == 2) {
      final sleepHour = int.tryParse(sleepParts[0]) ?? 22;
      final sleepMin = int.tryParse(sleepParts[1]) ?? 30;

      // Calculate sleep date trigger relative to today
      final sleepTriggerToday = DateTime(
        now.year,
        now.month,
        now.day,
        sleepHour,
        sleepMin,
      );

      // If now is past sleep target time, or early morning (before 5 AM)
      if (now.isAfter(sleepTriggerToday) || now.hour < 5) {
        isPastBedtime = true;
      }
    }

    // Check 2: Screen time limit exhausted
    bool isLimitExhausted =
        _todayLog.screenTimeMinutes >= _profile.screenTimeLimit;

    if (isPastBedtime || isLimitExhausted) {
      setState(() {
        _showHardTruthBlocker = true;
      });
    } else {
      setState(() {
        _showHardTruthBlocker = false;
      });
    }
  }

  void _bypassHardTruth() {
    setState(() {
      _showHardTruthBlocker = false;
      // Provide temporary 30-minute bypass by extending limit
      _profile.screenTimeLimit += 30;
    });
    _dbHelper.saveUserProfile(_profile);
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

    return Stack(
      children: [
        Scaffold(
          extendBody: true,
          backgroundColor: const Color(0xFF0B0C10),
          appBar: _selectedIndex == 0
              ? AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  actions: [
                    IconButton(
                      icon: const Icon(
                        Icons.nights_stay_outlined,
                        color: Color(0xFF8A2BE2),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SleepCalculatorScreen(
                              profile: _profile,
                              onProfileUpdated: _loadProfileAndLogs,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                )
              : null,
          body: _buildPageBody(),
          bottomNavigationBar: CustomNavBar(
            selectedIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        ),

        // Hard Truth Aggressive Blocker Overlay
        if (_showHardTruthBlocker)
          _HardTruthBlockerOverlay(
            onDismissed: _bypassHardTruth,
            screenTimeUsed: _todayLog.screenTimeMinutes,
            screenTimeLimit: _profile.screenTimeLimit,
          ),
      ],
    );
  }

  Widget _buildPageBody() {
    switch (_selectedIndex) {
      case 0:
        return DashboardScreen(
          profile: _profile,
          onProfileUpdated: _loadProfileAndLogs,
        );
      case 1:
        return TimersScreen(
          profile: _profile,
          onProfileUpdated: _loadProfileAndLogs,
        );
      case 2:
        return GoalsScreen(
          profile: _profile,
          onProfileUpdated: _loadProfileAndLogs,
        );
      case 3:
        return WishVaultScreen(
          profile: _profile,
          onProfileUpdated: _loadProfileAndLogs,
        );
      default:
        return Container();
    }
  }
}

class _HardTruthBlockerOverlay extends StatefulWidget {
  final VoidCallback onDismissed;
  final int screenTimeUsed;
  final int screenTimeLimit;

  const _HardTruthBlockerOverlay({
    required this.onDismissed,
    required this.screenTimeUsed,
    required this.screenTimeLimit,
  });

  @override
  State<_HardTruthBlockerOverlay> createState() =>
      _HardTruthBlockerOverlayState();
}

class _HardTruthBlockerOverlayState extends State<_HardTruthBlockerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  bool _isPressing = false;
  String _activeTruthPhrase = "";

  final List<String> _blockerPhrases = [
    "WAKE UP! Every minute scrolling is another minute you fall behind.",
    "Choose your dreams over short-term dopamine reels. Put it down.",
    "Remember what they did. Remember where you need to be. Step up.",
    "Scrolling won't pay the bills. You are acting like a beggar of attention. Close this phone.",
    "It is sleep time. Discipline separates the legends from the average.",
  ];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), // Hold for 3 seconds to bypass
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDismissed();
      }
    });

    _activeTruthPhrase =
        _blockerPhrases[DateTime.now().second % _blockerPhrases.length];
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0003), // Blood red-black
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Shock header
              Column(
                children: [
                  const SizedBox(height: 20),
                  const Icon(
                    Icons.report_problem,
                    color: Color(0xFFFF3366),
                    size: 80,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "LIMIT BREACHED",
                    style: TextStyle(
                      color: Color(0xFFFF3366),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Usage: ${widget.screenTimeUsed} mins / Limit: ${widget.screenTimeLimit} mins",
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),

              // Aggressive Motivation Text
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFF3366).withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  _activeTruthPhrase,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Hold-to-Dismiss button
              Column(
                children: [
                  GestureDetector(
                    onTapDown: (_) {
                      setState(() {
                        _isPressing = true;
                      });
                      _progressController.forward();
                    },
                    onTapUp: (_) {
                      setState(() {
                        _isPressing = false;
                      });
                      _progressController.reverse();
                    },
                    onTapCancel: () {
                      setState(() {
                        _isPressing = false;
                      });
                      _progressController.reverse();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 30,
                      ),
                      decoration: BoxDecoration(
                        color: _isPressing
                            ? const Color(0xFFFF3366).withValues(alpha: 0.2)
                            : const Color(0xFFFF3366),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFFF3366,
                            ).withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.timer, color: Colors.white),
                          const SizedBox(width: 10),
                          Text(
                            _isPressing ? "HOLDING..." : "HOLD FOR 3S TO SLEEP",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Progress loader bar
                  AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return Stack(
                        children: [
                          Container(
                            height: 4,
                            width: 200,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Container(
                            height: 4,
                            width: 200 * _progressController.value,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF3366),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
