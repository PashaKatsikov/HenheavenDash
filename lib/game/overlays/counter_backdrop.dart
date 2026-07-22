import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Decorative wood counter surface rendered behind the cooking stations so
/// the stations visually read as sitting "on the bar counter", rather than
/// floating over the raw kitchen background.
class CounterBackdrop extends StatelessWidget {
  const CounterBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = (constraints.maxHeight * 0.68).clamp(70.0, 190.0);
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.secondaryLight, AppColors.secondary, AppColors.secondaryDark],
                stops: [0, 0.35, 1],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.4), width: 2),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.32), blurRadius: 18, offset: const Offset(0, -4)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 6),
                  height: 4,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
