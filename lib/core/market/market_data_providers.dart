import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'market_data_service.dart';

/// The app-wide singleton feed. Created once, started immediately, and
/// disposed only when the whole app (ProviderContainer) goes away -- it is
/// intentionally *not* autoDispose, since it must keep ticking in the
/// background regardless of which screen is on-screen.
final marketDataServiceProvider = Provider<MarketDataService>((ref) {
  final service = MarketDataService(ticksPerSecondPerStock: kDefaultTickRate);
  service.start();
  ref.onDispose(service.dispose);
  return service;
});

/// Default rate: 1 tick/sec/stock (10 ticks/sec overall) -- a "realistic"
/// baseline. The debug tick-rate sheet can push this up to a stress-test
/// level (5+/sec/stock = 50+/sec overall) at runtime.
const double kDefaultTickRate = 1.0;
const double kStressTestTickRate = 5.0;

/// Mirrors the feed's current rate purely so widgets (e.g. an app bar
/// badge, the settings slider) can *display* it reactively. The feed
/// itself is the source of truth; this is updated alongside every call to
/// [MarketDataService.updateTickRate].
final tickRateProvider = StateProvider<double>((ref) => kDefaultTickRate);
