import 'package:flutter/material.dart';
import '../core/audio/audio_manager.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The main "start playing" action, styled as a farmyard picket gate instead
/// of a plain colored rectangle - the actual fence artwork is the button's
/// texture, topped with a hand-lettered "PLAY" plank and a little rooster
/// weather-vane silhouette so it reads as part of the farm, not a generic
/// CTA pill.
class FarmGateButton extends StatefulWidget {
  const FarmGateButton({super.key, required this.onPressed, this.width = 258, this.height = 78});

  final VoidCallback onPressed;
  final double width;
  final double height;

  @override
  State<FarmGateButton> createState() => _FarmGateButtonState();
}

class _FarmGateButtonState extends State<FarmGateButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final fontSize = (widget.height * 0.38).clamp(15.0, 32.0);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: () {
        AudioManager.instance.playClick();
        widget.onPressed();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: widget.height,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.accentDark, width: 2.5),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: _pressed ? 0.18 : 0.38), blurRadius: 12, offset: Offset(0, _pressed ? 2 : 6)),
                      BoxShadow(color: AppColors.accent.withValues(alpha: 0.4), blurRadius: 16, spreadRadius: -6),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset('assets/images/decor/decor_fence.png', fit: BoxFit.cover, alignment: Alignment.topCenter),
                        // Warm wash so the raw fence texture reads as a
                        // button surface, not a decor sprite pasted flat.
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.primary.withValues(alpha: 0.32),
                                AppColors.primaryDark.withValues(alpha: 0.58),
                              ],
                            ),
                          ),
                        ),
                        Center(
                          // FittedBox(scaleDown) is a safety net, not the primary
                          // sizing mechanism: playIconSize/fontSize above already
                          // pick a sensible size for the given button dimensions,
                          // but this guarantees the icon+"PLAY" row can never
                          // overflow (and get silently clipped by the ClipRRect
                          // above) no matter how compact a width/height this
                          // button is ever placed at - e.g. sitting inside the
                          // bottom shortcut row alongside the smaller menu tiles.
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'PLAY',
                              style: AppTextStyles.button.copyWith(fontSize: fontSize, color: AppColors.accent, letterSpacing: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
