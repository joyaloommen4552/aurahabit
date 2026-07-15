import 'package:flutter/material.dart';
import '../models/habit_data.dart';
import '../services/db_helper.dart';
import '../widgets/success_chart.dart';

class GoalsScreen extends StatefulWidget {
  final UserProfileModel profile;
  final VoidCallback onProfileUpdated;

  const GoalsScreen({
    super.key,
    required this.profile,
    required this.onProfileUpdated,
  });

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _dbHelper = DbHelper();
  List<GoalModel> _goals = [];
  List<DailyLogModel> _historicalLogs = [];
  bool _isLoading = true;
  String _selectedTab = 'daily'; // 'daily', 'weekly', 'monthly'

  final _goalTitleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _goalTitleController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final goalsList = await _dbHelper.getGoals();
    final logsList = await _dbHelper.getHistoricalLogs(7); // Last 7 days

    setState(() {
      _goals = goalsList;
      _historicalLogs = logsList;
      _isLoading = false;
    });
  }

  Future<void> _addGoal() async {
    final title = _goalTitleController.text.trim();
    if (title.isEmpty) return;

    final newGoal = GoalModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      type: _selectedTab,
      createdAt: DateTime.now(),
    );

    await _dbHelper.insertGoal(newGoal);
    _goalTitleController.clear();
    if (!mounted) return;
    Navigator.pop(context);
    _loadData();
    _awardXp(20, "Created New Goal!");
  }

  Future<void> _toggleGoal(GoalModel goal) async {
    final nextStatus = !goal.isCompleted;
    await _dbHelper.updateGoalStatus(goal.id, nextStatus);
    _loadData();
    if (nextStatus) {
      _awardXp(30, "Completed Goal!");
    }
  }

  Future<void> _deleteGoal(String id) async {
    await _dbHelper.deleteGoal(id);
    _loadData();
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
        backgroundColor: const Color(0xFF00FA9A),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showAddGoalDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F2833),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF00FA9A), width: 1.5),
          ),
          title: Text(
            "Add ${_selectedTab.toUpperCase()} Goal",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: _goalTitleController,
            style: const TextStyle(color: Colors.white),
            autofocus: true,
            decoration: InputDecoration(
              hintText: "Enter goal description...",
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF00FA9A)),
              ),
            ),
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
                backgroundColor: const Color(0xFF00FA9A),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _addGoal,
              child: const Text(
                "Add Goal",
                style: TextStyle(fontWeight: FontWeight.bold),
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
          child: CircularProgressIndicator(color: Color(0xFF00FA9A)),
        ),
      );
    }

    final filteredGoals = _goals.where((g) => g.type == _selectedTab).toList();
    final yearEndGoals = _goals.where((g) => g.type == 'yearEnd').toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      appBar: AppBar(
        title: const Text(
          "Planner",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Year-End Ultimate Goal Card
            const Text(
              "Year-End Ultimate Goal",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildYearEndSection(yearEndGoals),
            const SizedBox(height: 25),

            // Success Chart Section
            const Text(
              "Success Performance",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SuccessChart(logs: _historicalLogs),
            const SizedBox(height: 25),

            // Routine Goal Planner Header & Switch Tabs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Goal Planner",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Color(0xFF00FA9A),
                    size: 28,
                  ),
                  onPressed: _showAddGoalDialog,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Switcher Tabs row
            Row(
              children: [
                _buildTabButton('daily', 'Daily'),
                const SizedBox(width: 8),
                _buildTabButton('weekly', 'Weekly'),
                const SizedBox(width: 8),
                _buildTabButton('monthly', 'Monthly'),
              ],
            ),
            const SizedBox(height: 15),

            // Goal Items checklist
            if (filteredGoals.isEmpty)
              Container(
                height: 100,
                alignment: Alignment.center,
                child: Text(
                  "No goals set for this window.",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 13,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredGoals.length,
                itemBuilder: (context, index) {
                  final goal = filteredGoals[index];
                  return Dismissible(
                    key: Key(goal.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.centerRight,
                      color: Colors.red.withValues(alpha: 0.2),
                      child: const Icon(Icons.delete, color: Colors.redAccent),
                    ),
                    onDismissed: (direction) => _deleteGoal(goal.id),
                    child: Card(
                      color: const Color(0xFF1F2833).withValues(alpha: 0.12),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: goal.isCompleted
                              ? const Color(0xFF00FA9A).withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.04),
                        ),
                      ),
                      child: CheckboxListTile(
                        title: Text(
                          goal.title,
                          style: TextStyle(
                            color: goal.isCompleted
                                ? Colors.white54
                                : Colors.white,
                            decoration: goal.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            fontSize: 13,
                          ),
                        ),
                        value: goal.isCompleted,
                        onChanged: (val) => _toggleGoal(goal),
                        activeColor: const Color(0xFF00FA9A),
                        checkColor: Colors.black,
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 90), // Navigation spacing
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String tabKey, String label) {
    final isSelected = _selectedTab == tabKey;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTab = tabKey;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF00FA9A).withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF00FA9A)
                  : Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF00FA9A) : Colors.white60,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildYearEndSection(List<GoalModel> yearEndGoals) {
    if (yearEndGoals.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2833).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            const Text(
              "No Year-End Target Defined",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FA9A).withValues(alpha: 0.2),
                foregroundColor: const Color(0xFF00FA9A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                setState(() {
                  _selectedTab = 'yearEnd';
                });
                _showAddGoalDialog();
              },
              child: const Text(
                "Set Year-End Goal",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    final goal = yearEndGoals.first;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00FA9A).withValues(alpha: 0.1),
            const Color(0xFF1F2833).withValues(alpha: 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00FA9A).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.flag_rounded, color: Color(0xFF00FA9A), size: 20),
                  SizedBox(width: 8),
                  Text(
                    "ULTIMATE GOAL",
                    style: TextStyle(
                      color: Color(0xFF00FA9A),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.white38,
                  size: 18,
                ),
                onPressed: () => _deleteGoal(goal.id),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            goal.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                goal.isCompleted ? "Goal Completed!" : "Status: In Progress",
                style: TextStyle(
                  color: goal.isCompleted
                      ? const Color(0xFF00FA9A)
                      : Colors.white60,
                  fontSize: 12,
                ),
              ),
              Checkbox(
                value: goal.isCompleted,
                activeColor: const Color(0xFF00FA9A),
                checkColor: Colors.black,
                onChanged: (val) => _toggleGoal(goal),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
