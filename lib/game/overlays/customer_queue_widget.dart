import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/rustic_panel.dart';
import '../level_session.dart';

/// "At the counter" strip: every waiting customer stands in a horizontal row
/// right at the counter (matching the reference cafe games). Nothing here
/// sits on a boxed/tinted backdrop - the order label, food icon and
/// character portrait float directly over the kitchen art with just a soft
/// drop shadow for legibility, so the counter reads as guests standing in
/// the room rather than a stack of UI cards. Tapping any customer sends
/// their order to a free cooking station.
class CustomerQueueWidget extends StatelessWidget {
  const CustomerQueueWidget({
    super.key,
    required this.session,
    required this.onTapCustomer,
    this.height = 190,
  });

  final LevelSession session;
  final void Function(ActiveCustomer) onTapCustomer;

  /// The vertical room this strip has been given. Every element inside a
  /// customer (order icon, portrait, name, patience bar) is sized as a
  /// fraction of this, so guests scale up to read big on a tall iPad canvas
  /// and gracefully shrink on a short phone-in-landscape one - instead of a
  /// fixed pixel size that looked tiny ("like smurfs") in a tall slot.
  final double height;

  @override
  Widget build(BuildContext context) {
    final hasFreeStation = session.stations.any((s) => s.isFree);
    final queue = session.queue;

    return SizedBox(
      height: height,
      child: queue.isEmpty
          ? const Align(alignment: Alignment.centerLeft, child: _EmptyCounter())
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: queue.length,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final customer = queue[index];
                final assigned = customer.assignedStationId != null;
                final featured = index == 0;
                return _WalkIn(
                  key: ValueKey('counter-${customer.id}'),
                  child: _CounterCustomerCard(
                    customer: customer,
                    featured: featured,
                    slotHeight: height,
                    tappable: !assigned && hasFreeStation,
                    onTap: () => onTapCustomer(customer),
                  ),
                );
              },
            ),
    );
  }
}

/// One-shot "the customer walks up to the counter" animation: the card rises
/// and fades in. Because each card is keyed by the customer's id, a fresh
/// animation plays every time a new customer arrives.
class _WalkIn extends StatefulWidget {
  const _WalkIn({super.key, required this.child});
  final Widget child;

  @override
  State<_WalkIn> createState() => _WalkInState();
}

class _WalkInState extends State<_WalkIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 420))..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final t = curved.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - t)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

const List<Shadow> _labelShadow = [
  Shadow(color: Color(0xCC000000), blurRadius: 5, offset: Offset(0, 2)),
  Shadow(color: Color(0x99000000), blurRadius: 10),
];

/// A single guest standing at the counter: no card, no bubble, no boxed
/// background behind the character - just the order label, the dish icon,
/// the portrait and a slim patience bar floating over the kitchen art, each
/// piece grounded with its own soft shadow instead of a colored backdrop.
/// [featured] (the customer at the front of the line) renders a touch bigger
/// so it's clear who's next.
class _CounterCustomerCard extends StatelessWidget {
  const _CounterCustomerCard({
    required this.customer,
    required this.featured,
    required this.slotHeight,
    required this.tappable,
    required this.onTap,
  });

  final ActiveCustomer customer;
  final bool featured;
  final double slotHeight;
  final bool tappable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final assigned = customer.assignedStationId != null;
    final patienceColor = _patienceColor(customer.patienceFraction);

    // Everything is a fraction of the slot height. The front-of-line guest
    // ([featured]) gets a modest bump so it's clear who's served next. The
    // portrait deliberately claims the biggest share so the character - not
    // the order ticket - is the dominant, easily-readable element.
    final scale = featured ? 1.12 : 1.0;
    final portraitSize = slotHeight * 0.52 * scale;
    final iconSize = slotHeight * 0.24 * scale;
    final nameFont = (slotHeight * 0.072 * scale).clamp(11.0, 22.0);
    final barHeight = (slotHeight * 0.035).clamp(5.0, 10.0);
    final cardWidth = portraitSize + slotHeight * 0.22;

    return GestureDetector(
      onTap: tappable ? onTap : null,
      child: Opacity(
        opacity: assigned ? 0.62 : 1,
        child: SizedBox(
          width: cardWidth,
          // A scaleDown safety net so a very small slot (a short phone in
          // landscape) can never force the stacked column to overflow its
          // row - it stays pixel-proportional and simply shrinks to fit.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: cardWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Order: bare food icon + name, no ticket/bubble shape behind it.
                  Image.asset(
                    customer.recipe.foodIconPath,
                    width: iconSize,
                    height: iconSize,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    customer.recipe.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTextStyles.heading,
                      fontWeight: FontWeight.w700,
                      fontSize: nameFont,
                      height: 1.1,
                      color: AppColors.textOnDark,
                      shadows: _labelShadow,
                    ),
                  ),
                  SizedBox(height: slotHeight * 0.03),
                  // Soft ground shadow beneath the character instead of a
                  // colored plate/backdrop - keeps depth without a box.
                  SizedBox(
                    height: portraitSize + 8,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Positioned(
                          bottom: 2,
                          child: Container(
                            width: portraitSize * 0.62,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.28),
                            ),
                          ),
                        ),
                        Image.asset(customer.type.portraitPath, height: portraitSize, fit: BoxFit.contain),
                        if (assigned)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Image.asset(
                              'assets/images/kitchen/kit_pan_black.png',
                              width: iconSize * 0.5,
                              height: iconSize * 0.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: slotHeight * 0.028),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      width: cardWidth,
                      child: LinearProgressIndicator(
                        value: customer.patienceFraction,
                        minHeight: barHeight,
                        backgroundColor: Colors.black.withValues(alpha: 0.35),
                        color: patienceColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyCounter extends StatelessWidget {
  const _EmptyCounter();

  @override
  Widget build(BuildContext context) {
    return RusticPanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 16,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/kitchen/kit_serving_bell.png', width: 30, height: 30),
          const SizedBox(width: 10),
          Text('Counter is clear - waiting for guests...', style: AppTextStyles.caption.copyWith(color: AppColors.textOnDark.withValues(alpha: 0.8))),
        ],
      ),
    );
  }
}

Color _patienceColor(double fraction) {
  if (fraction > 0.55) return AppColors.success;
  if (fraction > 0.25) return AppColors.warning;
  return AppColors.cta;
}
