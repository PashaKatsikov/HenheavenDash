import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';

const List<Shadow> _numberShadow = [
  Shadow(color: Color(0xDD000000), blurRadius: 5, offset: Offset(0, 2)),
  Shadow(color: Color(0x99000000), blurRadius: 10),
];

/// A currency readout: an illustrated coin sack / basket icon with the
/// animated number floating right next to it - no boxed glass chip behind
/// it. The icon itself (a hand-painted sack, not a flat coin glyph) does the
/// work of reading as "currency", so the count just needs a readable shadow.
class CurrencyChip extends StatefulWidget {
  const CurrencyChip({
    super.key,
    required this.iconPath,
    required this.value,
    this.compact = false,
    this.prefix = '',
  });

  final String iconPath;
  final int value;
  final bool compact;
  final String prefix;

  @override
  State<CurrencyChip> createState() => _CurrencyChipState();
}

class _CurrencyChipState extends State<CurrencyChip> {
  @override
  Widget build(BuildContext context) {
    final size = widget.compact ? 28.0 : 38.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(widget.iconPath, width: size, height: size),
        const SizedBox(width: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
          child: Text(
            '${widget.prefix}${widget.value}',
            key: ValueKey(widget.value),
            style: AppTextStyles.hudNumber.copyWith(
              fontSize: widget.compact ? 16 : 21,
              shadows: _numberShadow,
            ),
          ),
        ),
      ],
    );
  }
}
