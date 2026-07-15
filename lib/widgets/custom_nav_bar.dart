import 'dart:ui';
import 'package:flutter/material.dart';

class CustomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const CustomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      height: 70,
      decoration: BoxDecoration(
        color: const Color(
          0xFF1F2833,
        ).withValues(alpha: 0.2), // transparent slate
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                0,
                Icons.dashboard_outlined,
                Icons.dashboard,
                "Home",
              ),
              _buildNavItem(1, Icons.timer_outlined, Icons.timer, "Focus"),
              _buildNavItem(
                2,
                Icons.event_note_outlined,
                Icons.event_note,
                "Planner",
              ),
              _buildNavItem(3, Icons.stars_outlined, Icons.stars, "Vault"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData outlineIcon,
    IconData filledIcon,
    String label,
  ) {
    final isSelected = selectedIndex == index;
    final Color activeColor = _getActiveColorForTab(index);

    return InkWell(
      onTap: () => onTap(index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isSelected ? filledIcon : outlineIcon,
              color: isSelected
                  ? activeColor
                  : Colors.white.withValues(alpha: 0.5),
              size: 24,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? activeColor
                  : Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getActiveColorForTab(int index) {
    switch (index) {
      case 0:
        return const Color(0xFF66FCF1); // Cyan
      case 1:
        return const Color(0xFFFF7F50); // Orange
      case 2:
        return const Color(0xFF00FA9A); // Green
      case 3:
        return const Color(0xFF8A2BE2); // Purple
      default:
        return Colors.white;
    }
  }
}
