import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/habit_data.dart';
import '../services/db_helper.dart';

class SleepCalculatorScreen extends StatefulWidget {
  final UserProfileModel profile;
  final VoidCallback onProfileUpdated;

  const SleepCalculatorScreen({
    super.key,
    required this.profile,
    required this.onProfileUpdated,
  });

  @override
  State<SleepCalculatorScreen> createState() => _SleepCalculatorScreenState();
}

class _SleepCalculatorScreenState extends State<SleepCalculatorScreen> {
  final _dbHelper = DbHelper();
  TimeOfDay _selectedWakeTime = const TimeOfDay(hour: 7, minute: 0);
  List<DateTime> _bedTimes = [];
  List<DateTime> _wakeUpTimes = [];
  bool _calculatingBedtime = true;
  final List<String> _customTruths = [];
  final _truthController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _calculateTimes();
    _loadCustomTruths();
  }

  void _loadCustomTruths() {
    // Default hard truths
    _customTruths.addAll([
      "Wake up. Every minute scrolling is another minute you fall behind.",
      "Put the phone down. Focus on your dreams, not other people's reels.",
      "Remember what they did. Remember where you need to be. Step up your life.",
      "Scrolling won't pay the bills. Sleep right now.",
    ]);
  }

  void _calculateTimes() {
    final now = DateTime.now();

    if (_calculatingBedtime) {
      // Calculate sleep times to wake up at _selectedWakeTime
      // We target cycles: 6 cycles (9 hrs), 5 cycles (7.5 hrs), 4 cycles (6 hrs)
      final tomorrow = DateTime(
        now.year,
        now.month,
        now.day + 1,
        _selectedWakeTime.hour,
        _selectedWakeTime.minute,
      );
      _bedTimes = List.generate(4, (index) {
        final cycles = 6 - index; // 6, 5, 4, 3 cycles
        final minutesNeeded = (cycles * 90) + 14; // add 14 mins to fall asleep
        return tomorrow.subtract(Duration(minutes: minutesNeeded));
      });
    } else {
      // If I sleep right now, when should I wake up?
      // Adding 90 min cycles + 14 mins
      final sleepTime = now.add(const Duration(minutes: 14));
      _wakeUpTimes = List.generate(4, (index) {
        final cycles = index + 3; // 3, 4, 5, 6 cycles (4.5h, 6h, 7.5h, 9h)
        return sleepTime.add(Duration(minutes: cycles * 90));
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedWakeTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF8A2BE2),
              onPrimary: Colors.white,
              surface: Color(0xFF1F2833),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedWakeTime = picked;
        _calculateTimes();
      });

      // Save targeted bedtime setting to database profile
      final hr = picked.hour.toString().padLeft(2, '0');
      final min = picked.minute.toString().padLeft(2, '0');
      widget.profile.sleepTargetTime = "$hr:$min";
      await _dbHelper.saveUserProfile(widget.profile);
      widget.onProfileUpdated();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      appBar: AppBar(
        title: const Text(
          "Celestial Sleep",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Celestial Moon banner card
            Container(
              height: 140,
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF8A2BE2).withValues(alpha: 0.3),
                    const Color(0xFF4B0082).withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF8A2BE2).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  CustomPaint(
                    size: const Size(80, 80),
                    painter: _MoonPainter(),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Sleep Cycle Math",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "A single sleep cycle is 90 minutes. Waking up in between cycles causes grogginess. Target 5-6 full cycles.",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Tab switchers
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _calculatingBedtime = true;
                        _calculateTimes();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _calculatingBedtime
                            ? const Color(0xFF8A2BE2).withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _calculatingBedtime
                              ? const Color(0xFF8A2BE2)
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          "Wake Up at...",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _calculatingBedtime = false;
                        _calculateTimes();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_calculatingBedtime
                            ? const Color(0xFF8A2BE2).withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: !_calculatingBedtime
                              ? const Color(0xFF8A2BE2)
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          "Sleep Now",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            if (_calculatingBedtime) ...[
              const Text(
                "If I want to wake up at:",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () => _selectTime(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2833).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedWakeTime.format(context),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(Icons.access_time, color: Color(0xFF8A2BE2)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "I should go to bed at one of these times:",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 10),
              ..._bedTimes.map((time) {
                final cycleCount = 6 - _bedTimes.indexOf(time);
                final timeStr =
                    "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
                return _buildTimeCard(
                  timeStr,
                  "$cycleCount Cycles (${cycleCount * 1.5}h Sleep)",
                );
              }),
            ] else ...[
              const Text(
                "If I go to bed right now, I should wake up at:",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 10),
              ..._wakeUpTimes.map((time) {
                final cycleCount = _wakeUpTimes.indexOf(time) + 3;
                final timeStr =
                    "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
                return _buildTimeCard(
                  timeStr,
                  "$cycleCount Cycles (${cycleCount * 1.5}h Sleep)",
                );
              }),
            ],
            const SizedBox(height: 30),

            // Hard truth alert setup section
            const Text(
              "Hard Truth Mode",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              "Triggers alarms and scrolling overrides when you are using your phone past bedtime limit thresholds.",
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
            const SizedBox(height: 15),

            // Hard truth toggle card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: widget.profile.hardTruthMode
                    ? const Color(0xFFFF3366).withValues(alpha: 0.08)
                    : const Color(0xFF1F2833).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.profile.hardTruthMode
                      ? const Color(0xFFFF3366).withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: widget.profile.hardTruthMode
                            ? const Color(0xFFFF3366)
                            : Colors.white54,
                      ),
                      const SizedBox(width: 15),
                      const Text(
                        "Enable Blocker & Alerts",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: widget.profile.hardTruthMode,
                    activeThumbColor: const Color(0xFFFF3366),
                    onChanged: (val) async {
                      setState(() {
                        widget.profile.hardTruthMode = val;
                      });
                      await _dbHelper.saveUserProfile(widget.profile);
                      widget.onProfileUpdated();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Add custom motivational alert
            const Text(
              "Your Custom Alert Messages:",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _truthController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Add your custom hard truth wake-up line...",
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      filled: true,
                      fillColor: const Color(
                        0xFF1F2833,
                      ).withValues(alpha: 0.15),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF8A2BE2)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle,
                    color: Color(0xFF8A2BE2),
                    size: 30,
                  ),
                  onPressed: () {
                    final text = _truthController.text.trim();
                    if (text.isNotEmpty) {
                      setState(() {
                        _customTruths.insert(0, text);
                        _truthController.clear();
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Motivation alert phrase added!"),
                          backgroundColor: Color(0xFF8A2BE2),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 15),
            ..._customTruths.map(
              (truth) => Card(
                color: const Color(0xFF1F2833).withValues(alpha: 0.15),
                margin: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.format_quote,
                    color: Color(0xFFFF3366),
                    size: 20,
                  ),
                  title: Text(
                    truth,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.white38,
                      size: 18,
                    ),
                    onPressed: () {
                      setState(() {
                        _customTruths.remove(truth);
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 90), // Spacing for bottom navbar
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard(String time, String info) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2833).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            time,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            info,
            style: const TextStyle(
              color: Color(0xFF8A2BE2),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.5;

    // Glowing halo
    final glowPaint = Paint()
      ..color = const Color(0xFF8A2BE2).withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius + 5, glowPaint);

    // Crescent Moon shape
    final moonPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFE6E6FA), // Lavender
          Color(0xFF8A2BE2), // Purple
        ],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    path.addArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi,
    );
    // Cut out inner arc to form crescent moon
    path.arcToPoint(
      Offset(center.dx, center.dy - radius),
      radius: Radius.circular(radius * 1.25),
      clockwise: false,
    );
    path.close();

    canvas.drawPath(path, moonPaint);

    // Draw little celestial stars around the moon
    final rand = math.Random(10);
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.7);
    for (int i = 0; i < 4; i++) {
      final x = rand.nextDouble() * size.width;
      final y = rand.nextDouble() * size.height;
      if ((x - center.dx).abs() > radius * 0.7 ||
          (y - center.dy).abs() > radius * 0.7) {
        canvas.drawCircle(
          Offset(x, y),
          rand.nextDouble() * 1.5 + 0.5,
          starPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
