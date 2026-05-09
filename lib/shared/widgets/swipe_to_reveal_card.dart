import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:life_replay/core/theme/app_theme.dart';

/// Wraps [child] with a horizontal swipe-to-left gesture that reveals
/// Edit (amber) and Delete (red) action buttons beneath the card.
///
/// The card slides left to expose the actions; tapping the card or
/// dragging it back snaps it closed.
class SwipeToRevealCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final BorderRadius borderRadius;

  const SwipeToRevealCard({
    super.key,
    required this.child,
    required this.onEdit,
    required this.onDelete,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
  });

  @override
  State<SwipeToRevealCard> createState() => _SwipeToRevealCardState();
}

class _SwipeToRevealCardState extends State<SwipeToRevealCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slide;

  static const double _revealWidth = 128;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _slide = Tween<double>(begin: 0, end: -_revealWidth).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    final delta = d.primaryDelta ?? 0;
    _ctrl.value = (_ctrl.value + (-delta / _revealWidth)).clamp(0, 1);
  }

  void _onDragEnd(DragEndDetails d) {
    if (_ctrl.value > 0.28) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  void _close() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      behavior: HitTestBehavior.translucent,
      child: ClipRect(
        child: Stack(
          children: [
            // ── Action panel (shown behind card when swiped) ──────────────
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: _revealWidth,
              child: Row(
                children: [
                  // Edit
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _close();
                        widget.onEdit();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.secondary,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(14),
                            bottomLeft: const Radius.circular(14),
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.edit, color: Colors.white, size: 22),
                            SizedBox(height: 4),
                            Text(
                              'Edit',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Delete
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _close();
                        widget.onDelete();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.error,
                          borderRadius: BorderRadius.only(
                            topRight: widget.borderRadius.topRight,
                            bottomRight: widget.borderRadius.bottomRight,
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.trash, color: Colors.white, size: 22),
                            SizedBox(height: 4),
                            Text(
                              'Delete',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
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

            // ── Sliding card ──────────────────────────────────────────────
            AnimatedBuilder(
              animation: _slide,
              builder: (_, child) =>
                  Transform.translate(offset: Offset(_slide.value, 0), child: child),
              child: GestureDetector(
                // Tap on the card itself closes the swipe
                onTap: _ctrl.value > 0.05 ? _close : null,
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

