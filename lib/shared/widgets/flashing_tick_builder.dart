import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/market/tick.dart';
import '../../core/theme/app_theme.dart';

/// Subscribes to a single symbol's live [Tick] stream and briefly flashes
/// a green/red overlay behind [builder]'s content whenever a new tick
/// moves the price up or down.
///
/// This is the one place in the app that touches [ValueNotifier] directly
/// for prices. Every row across Watchlist, Market Overview, and Holdings
/// is built on top of this widget, which keeps three things true
/// everywhere at once:
///
/// 1. Only the row(s) actually bound to a symbol rebuild when that
///    symbol ticks -- siblings showing other symbols are untouched, and
///    the parent list/grid is never rebuilt just because a price moved.
/// 2. The rebuild is scoped to a [State.setState] on this small widget,
///    not a `Provider`/`Riverpod` invalidation, so there is no extra
///    layer of indirection on the hottest path in the app.
/// 3. Flash color/direction is derived from the *tick's own* direction
///    (up/down/flat vs. the previous tick), independent of the
///    day-over-day change shown in the change/change% columns.
class FlashingTickBuilder extends StatefulWidget {
  const FlashingTickBuilder({
    super.key,
    required this.ticker,
    required this.builder,
    this.flashDuration = const Duration(milliseconds: 450),
  });

  final ValueListenable<Tick> ticker;
  final Widget Function(BuildContext context, Tick tick, Color? flashOverlay) builder;
  final Duration flashDuration;

  @override
  State<FlashingTickBuilder> createState() => _FlashingTickBuilderState();
}

class _FlashingTickBuilderState extends State<FlashingTickBuilder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Animation<Color?>? _flashAnimation;
  late Tick _tick;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.flashDuration);
    _tick = widget.ticker.value;
    widget.ticker.addListener(_onTick);
  }

  @override
  void didUpdateWidget(covariant FlashingTickBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ticker != widget.ticker) {
      oldWidget.ticker.removeListener(_onTick);
      widget.ticker.addListener(_onTick);
      _tick = widget.ticker.value;
    }
  }

  void _onTick() {
    final newTick = widget.ticker.value;
    if (newTick.direction != TickDirection.flat) {
      final flashColor = newTick.direction == TickDirection.up
          ? MarketColors.upFlash
          : MarketColors.downFlash;
      _flashAnimation = ColorTween(begin: flashColor, end: flashColor.withAlpha(0))
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      _controller.forward(from: 0);
    }
    if (mounted) {
      setState(() => _tick = newTick);
    }
  }

  @override
  void dispose() {
    widget.ticker.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => widget.builder(context, _tick, _flashAnimation?.value),
    );
  }
}
