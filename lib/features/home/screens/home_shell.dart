import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../market_overview/screens/market_overview_screen.dart';
import '../../trading/screens/holdings_screen.dart';
import '../../watchlist/screens/watchlists_screen.dart';

/// Which bottom-nav tab is selected. Exposed as a provider (rather than
/// local State) so other screens -- notably the order confirmation screen
/// -- can jump straight to a tab (e.g. "View holdings") without pushing a
/// second, disconnected instance of that screen onto the nav stack.
final homeTabIndexProvider = StateProvider<int>((ref) => 0);

const int watchlistsTabIndex = 0;
const int marketTabIndex = 1;
const int holdingsTabIndex = 2;

/// Root shell: a bottom nav bar over the app's three main surfaces.
/// Uses [IndexedStack] so switching tabs never rebuilds/disposes the
/// other screens -- scroll position and any in-flight animations are
/// preserved, and the market data feed keeps updating widgets on
/// off-screen tabs exactly as it does for the visible one.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(homeTabIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [
          WatchlistsScreen(),
          MarketOverviewScreen(),
          HoldingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => ref.read(homeTabIndexProvider.notifier).state = i,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.visibility_outlined), selectedIcon: Icon(Icons.visibility), label: 'Watchlists'),
          NavigationDestination(icon: Icon(Icons.show_chart), label: 'Market'),
          NavigationDestination(icon: Icon(Icons.pie_chart_outline), selectedIcon: Icon(Icons.pie_chart), label: 'Holdings'),
        ],
      ),
    );
  }
}
