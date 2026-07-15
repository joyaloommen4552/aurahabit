import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/habit_data.dart';
import '../services/db_helper.dart';
import '../widgets/glow_particles.dart';

class WishVaultScreen extends StatefulWidget {
  final UserProfileModel profile;
  final VoidCallback onProfileUpdated;

  const WishVaultScreen({
    super.key,
    required this.profile,
    required this.onProfileUpdated,
  });

  @override
  State<WishVaultScreen> createState() => _WishVaultScreenState();
}

class _WishVaultScreenState extends State<WishVaultScreen>
    with SingleTickerProviderStateMixin {
  final _dbHelper = DbHelper();
  List<WishModel> _wishes = [];
  bool _isLoading = true;

  // Particle background states
  late AnimationController _particleController;
  final List<GlowParticle> _particles = [];

  // Controllers for adding a wish
  final _wishTitleController = TextEditingController();
  final _wishDescController = TextEditingController();

  // Controllers for manual roadmap planner
  final _dailyController = TextEditingController();
  final _weeklyController = TextEditingController();
  final _monthlyController = TextEditingController();
  final _yearEndController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _generateParticles();
    _loadWishes();
  }

  @override
  void dispose() {
    _particleController.dispose();
    _wishTitleController.dispose();
    _wishDescController.dispose();
    _dailyController.dispose();
    _weeklyController.dispose();
    _monthlyController.dispose();
    _yearEndController.dispose();
    super.dispose();
  }

  void _generateParticles() {
    final random = math.Random();
    for (int i = 0; i < 20; i++) {
      _particles.add(
        GlowParticle(
          x: random.nextDouble() * 400,
          y: random.nextDouble() * 800,
          speed: random.nextDouble() * 0.3 + 0.1,
          radius: random.nextDouble() * 3 + 1,
          opacity: random.nextDouble() * 0.6 + 0.3,
          randomOffset: random.nextDouble() * 100,
        ),
      );
    }
  }

  Future<void> _loadWishes() async {
    final list = await _dbHelper.getWishes();
    setState(() {
      _wishes = list;
      _isLoading = false;
    });
  }

  Future<void> _addWish() async {
    final title = _wishTitleController.text.trim();
    if (title.isEmpty) return;

    final newWish = WishModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: _wishDescController.text.trim(),
      createdAt: DateTime.now(),
    );

    await _dbHelper.insertWish(newWish);
    _wishTitleController.clear();
    _wishDescController.clear();
    if (!mounted) return;
    Navigator.pop(context);
    _loadWishes();
    _awardXp(30, "Logged a New Wish in Vault!");
  }

  Future<void> _deleteWish(String id) async {
    await _dbHelper.deleteWish(id);
    _loadWishes();
  }

  // --- MANUAL ROADMAP ACTIVATION ---
  Future<void> _activateRoadmap(String wishId) async {
    final daily = _dailyController.text.trim();
    final weekly = _weeklyController.text.trim();
    final monthly = _monthlyController.text.trim();
    final yearEnd = _yearEndController.text.trim();

    if (daily.isEmpty && weekly.isEmpty && monthly.isEmpty && yearEnd.isEmpty) {
      return;
    }

    final now = DateTime.now();

    // Insert active goals based on fields completed
    if (daily.isNotEmpty) {
      await _dbHelper.insertGoal(
        GoalModel(
          id: "d_${now.millisecondsSinceEpoch}",
          title: daily,
          type: 'daily',
          createdAt: now,
          wishId: wishId,
        ),
      );
    }
    if (weekly.isNotEmpty) {
      await _dbHelper.insertGoal(
        GoalModel(
          id: "w_${now.millisecondsSinceEpoch}",
          title: weekly,
          type: 'weekly',
          createdAt: now,
          wishId: wishId,
        ),
      );
    }
    if (monthly.isNotEmpty) {
      await _dbHelper.insertGoal(
        GoalModel(
          id: "m_${now.millisecondsSinceEpoch}",
          title: monthly,
          type: 'monthly',
          createdAt: now,
          wishId: wishId,
        ),
      );
    }
    if (yearEnd.isNotEmpty) {
      await _dbHelper.insertGoal(
        GoalModel(
          id: "y_${now.millisecondsSinceEpoch}",
          title: yearEnd,
          type: 'yearEnd',
          createdAt: now,
          wishId: wishId,
        ),
      );
    }

    // Clear and pop
    _dailyController.clear();
    _weeklyController.clear();
    _monthlyController.clear();
    _yearEndController.clear();
    if (!mounted) return;
    Navigator.pop(context);

    _awardXp(50, "Activated Dream Habits Roadmap!");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Roadmap habits loaded into Planner checklists!",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF8A2BE2),
      ),
    );
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
        backgroundColor: const Color(0xFF8A2BE2),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showAddWishDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F2833),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF8A2BE2), width: 1.5),
          ),
          title: const Text(
            "Lock in a Wish / Dream",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _wishTitleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "What is your wish? (e.g. Learn Guitar)",
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF8A2BE2)),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _wishDescController,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: "Why is this important to you?",
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF8A2BE2)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8A2BE2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _addWish,
              child: const Text(
                "Save to Vault",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRoadmapSheet(WishModel wish) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1F2833),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "Break Down: ${wish.title}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.psychology, color: Color(0xFF8A2BE2)),
                ],
              ),
              const SizedBox(height: 5),
              const Text(
                "Map out daily, weekly, monthly, and year-end targets to turn this dream into real accomplishments.",
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
              const SizedBox(height: 20),
              _buildRoadmapField(
                _dailyController,
                "🏃 Daily Habit (e.g. Practice chords for 15 mins)",
              ),
              const SizedBox(height: 12),
              _buildRoadmapField(
                _weeklyController,
                "📅 Weekly Goal (e.g. Learn 1 full lesson scale)",
              ),
              const SizedBox(height: 12),
              _buildRoadmapField(
                _monthlyController,
                "🏆 Monthly Goal (e.g. Master a basic song)",
              ),
              const SizedBox(height: 12),
              _buildRoadmapField(
                _yearEndController,
                "🌟 Year-End Target (e.g. Play a full song live)",
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8A2BE2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => _activateRoadmap(wish.id),
                  child: const Text(
                    "Activate Habits & Goals",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoadmapField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 12,
        ),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.2),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8A2BE2)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      body: Stack(
        children: [
          // Glowing star particles backdrop
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: GlowParticlesPainter(
                  particles: _particles,
                  animationValue: _particleController.value,
                ),
              );
            },
          ),

          // Core UI contents
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Wish Vault",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle,
                          color: Color(0xFF8A2BE2),
                          size: 30,
                        ),
                        onPressed: _showAddWishDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Store your life wishes and divide them into daily habits to guide your path.",
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 25),

                  // Wishes listing
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF8A2BE2),
                      ),
                    )
                  else if (_wishes.isEmpty)
                    Container(
                      height: 200,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.stars,
                            color: Colors.white24,
                            size: 50,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Your Wish Vault is currently empty.",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _wishes.length,
                      itemBuilder: (context, index) {
                        final wish = _wishes[index];
                        return Card(
                          color: const Color(0xFF1F2833).withValues(alpha: 0.2),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: const Color(
                                0xFF8A2BE2,
                              ).withValues(alpha: 0.2),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        wish.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.white38,
                                        size: 18,
                                      ),
                                      onPressed: () => _deleteWish(wish.id),
                                    ),
                                  ],
                                ),
                                if (wish.description.isNotEmpty) ...[
                                  const SizedBox(height: 5),
                                  Text(
                                    wish.description,
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 15),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF8A2BE2,
                                        ).withValues(alpha: 0.15),
                                        foregroundColor: const Color(
                                          0xFF8A2BE2,
                                        ),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        side: const BorderSide(
                                          color: Color(0xFF8A2BE2),
                                          width: 1,
                                        ),
                                      ),
                                      onPressed: () => _showRoadmapSheet(wish),
                                      icon: const Icon(
                                        Icons.playlist_add_check,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        "Plan Roadmap",
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
                        );
                      },
                    ),
                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
