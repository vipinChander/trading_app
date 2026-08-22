# Trading App — 021 Flutter Assignment

A mock trading app built in Flutter: multi-watchlist tracking, a continuously
updating live market overview, a Buy/Sell ticket backed by a simulated
wallet/margin balance, and a Holdings view with live, sortable P&L.

There is no real backend. A single in-app mock market-data feed
(`MarketDataService`) is the one source of price data for every screen.

## Running it

```bash
flutter pub get
flutter run
```

**This currently launches on Chrome/web out of the box** — the fastest way to
see all four features end-to-end with zero extra tooling.

> **Platform folders note.** This project was built in a sandboxed
> environment with no network access to Flutter's SDK/artifact servers, so I
> could not run `flutter create` locally to generate version-matched
> `android/`/`ios/` scaffolding (Gradle wrapper binaries, AGP/Kotlin
> versions, Xcode project files) tied to a specific Flutter install. Rather
> than ship platform config that might not match your SDK version and fail
> with a confusing Gradle/CocoaPods error, `android/` and `ios/` aren't
> included. **To run on an Android emulator/device or iOS simulator**, run
> this once at the repo root:
>
> ```bash
> flutter create --platforms=android,ios .
> ```
>
> This only (re)generates the platform scaffolding directories — it never
> touches `lib/`, `pubspec.yaml`, `test/`, or this README. After that,
> `flutter run` (or `flutter run -d <device>`) works normally. Everything
> graded — architecture, features, state management, persistence, tests —
> lives entirely in `lib/` and `test/` and is unaffected by this step.

To run the test suite:

```bash
flutter test
```

## The 10 stocks

`RELIANCE, TCS, INFY, HDFCBANK, ICICIBANK, SBIN, ITC, LT, BHARTIARTL, AXISBANK`
— defined once in `lib/core/constants/stock_catalog.dart` with plausible
starting prices, and used everywhere else by symbol.

## Architecture

Feature-first folders, with a small `core/` for cross-cutting concerns and a
`shared/` for the one widget every price display is built on:

```
lib/
  core/
    constants/stock_catalog.dart      the fixed universe of 10 stocks
    market/                            the mock feed (see below)
    persistence/app_database.dart      single Hive box + key registry
    theme/                             colors, text styles
    utils/                             Money, validators, id generator, formatters
  features/
    watchlist/                         Feature 1
    market_overview/                   Feature 2
    trading/                           Features 3 & 4 (they share one engine — see below)
    home/                              bottom-nav shell tying the three tabs together
  shared/widgets/
    flashing_tick_builder.dart          the shared live-price + flash primitive
    empty_state.dart
```

**State management: Riverpod.** Each feature owns a `StateNotifier` (or a
plain `Provider`/`StateProvider` where a notifier is overkill) backing its
screens, plus a repository that reads/writes Hive. This keeps business logic
out of widgets and easy to unit test without touching the widget tree.

**Why Buy/Sell ticket and Holdings share one feature (`trading/`) instead of
being two separate ones:** they operate on the exact same three pieces of
state — wallet balance, holdings, order history — and a submitted order has
to update all three atomically. `TradingService.submit()` is the one place
that validation + mutation happens, so the rules ("insufficient balance",
"not enough shares held") can't be duplicated or bypassed by a second code
path. Splitting the *screens* across two folders while forcing them to share
one *engine* would just move the coupling around without removing it.

### The mock market-data feed (`core/market/market_data_service.dart`)

* One `ValueNotifier<Tick>` per symbol, created once and shared by the whole
  app. Every screen — Watchlist rows, Market Overview cells, Holdings rows,
  the Buy/Sell ticket's live LTP — reads the *same* notifier for a given
  symbol. This is what makes "two watchlists containing the same stock show
  identical live prices" true by construction rather than by careful
  synchronization.
* One independent `Timer` per symbol, so "N ticks/sec per stock" is literal.
  Ten timers (even at a stress-tested 5/sec each) cost the Dart VM nothing;
  the part that actually matters for smoothness is how much *widget* work
  each tick triggers — which is the next point.
* `FlashingTickBuilder` (`shared/widgets/flashing_tick_builder.dart`) is the
  single widget every live price row is built on. It subscribes directly to
  one symbol's `ValueNotifier` and calls `setState` on itself alone when a
  tick arrives — a tick for RELIANCE re-renders exactly the RELIANCE
  row/cell, never a sibling, never the parent `ListView`. It also derives
  the brief green/red flash from the tick's own up/down direction.
* The service is a plain Dart object, independent of the widget tree, so it
  keeps ticking regardless of which tab is visible — the reason "navigate
  away and come back" never shows a stale price. `HomeShell` also uses an
  `IndexedStack` for its three tabs (not a rebuilt `Navigator`/`PageView`),
  so the off-screen screens' widgets aren't even torn down while hidden.
* Tick rate is configurable at runtime from the Market tab's tune icon
  (`TickRateControlSheet`) — a slider plus a one-tap "Stress test (5/sec)"
  button that jumps straight to the 50-ticks/sec-overall scenario called out
  in the assignment.
* Random walk with light mean-reversion toward the session's opening price
  and a floor/ceiling clamp (50%–200% of open), so prices move realistically
  tick to tick without ever drifting to zero or running away over a long
  session.

### Money handling (`core/utils/money.dart`)

`Money` stores an integer number of **paise** (1 rupee = 100 paise) and never
does arithmetic in `double`. Every balance, order value, and P&L figure in
the app is exact integer math — `10.10 + 0.20` really is `10.30`, not
`10.299999999999999`. The only `double` allowed near money is a **derived
percentage** for display (`change%`, `P&L%`), which is a ratio, not a
currency amount, and is never fed back into a `Money` value.

### Holdings: keeping "live per-row" and "correct sort order" both true

Every `HoldingRow` binds directly to its own symbol's ticker, so P&L numbers
update every tick without the list rebuilding. But *re-sorting* 10 rows on
every one of up to 50 ticks/sec would add cost a human can't perceive while
fighting the "don't rebuild the whole list" requirement — so the sort order
is instead recomputed on a throttled ~500ms cadence (see
`_SortedHoldingsList` in `holdings_screen.dart`), plus immediately whenever a
buy/sell actually changes which holdings exist. A row crossing from loss to
gain reorders well within a second — visually instant to a person — without
the list re-sorting 50 times a second for no visible benefit. The aggregate
summary card at the top recomputes on every tick (via `Listenable.merge`
across held symbols), since summing ≤10 numbers is trivial and it's what
keeps "the total always equals the sum of the rows" exactly true at any
instant.

### Persistence

A single Hive box (`core/persistence/app_database.dart`), one key per
collection (`watchlists_v1`, `wallet_balance_paise_v1`, `holdings_v1`,
`orders_v1`), each storing a plain JSON-friendly `Map`/`List`/`int` via each
model's own `toJson`/`fromJson`. Deliberately **not** using Hive's generated
`TypeAdapter`s, which need a `build_runner` codegen step — that would violate
"runs with `flutter pub get && flutter run`, no extra setup."

### Error & edge-case handling

* Quantity input is validated centrally (`core/utils/validators.dart`):
  empty, non-numeric, fractional, zero, negative, and unreasonably large
  quantities are all rejected with an inline message before submit is even
  attempted.
* `TradingService.submit()` re-validates margin/holding server-side (i.e.
  independent of whatever the UI already checked) before mutating any
  state, and mutates wallet + holdings + order history together or not at
  all — a rejected order leaves every piece of state untouched.
* The submit button disables itself while a submission is in flight, so a
  rapid double-tap can't create two orders from one click.
* If Hive fails to initialize on launch, the app shows a plain error screen
  instead of a crash with no explanation.
* Deleting a watchlist while its detail screen is still open (e.g. from
  another surface) is handled gracefully rather than crashing on a null
  lookup.
* `MarketDataService` clamps prices to a sane band and throws a clear
  `ArgumentError` for an unknown symbol rather than silently returning
  garbage.

## Feature → code map

| Feature | Screens | State |
|---|---|---|
| 1. Watchlist | `features/watchlist/screens/*` | `WatchlistController` (Hive-backed) |
| 2. Live Prices Mimic | `features/market_overview/screens/market_overview_screen.dart` | `MarketDataService` directly |
| 3. Buy/Sell Ticket | `features/trading/screens/buy_sell_ticket_screen.dart`, `order_confirmation_screen.dart` | `TradingService` + `WalletController`/`HoldingsController`/`OrderHistoryController` |
| 4. Holdings | `features/trading/screens/holdings_screen.dart` | same trading state, read-only here |

## Tests

`flutter test` runs:

* `test/core/money_test.dart` — exact decimal arithmetic, formatting, no
  float drift.
* `test/core/market_data_service_test.dart` — the feed seeds correctly,
  ticks actually fire at roughly the configured rate, prices never drift to
  zero, two readers of the same symbol always agree, rate clamping.
* `test/core/validators_test.dart` — every quantity edge case from the spec
  (empty/non-numeric/fractional/zero/negative/oversized).
* `test/features/trading/trading_service_test.dart` — buy/sell math,
  weighted-average cost across multiple buys, insufficient-balance and
  oversell rejection (and that a rejected order changes nothing), a holding
  disappearing at zero quantity, order-history ordering.
* `test/features/watchlist/watchlist_controller_test.dart` — CRUD, no
  duplicate adds, reorder semantics, two watchlists sharing a symbol
  independently, and a simulated restart (new controller instance reading
  the same underlying Hive box) restoring identical state.
* `test/widget_smoke_test.dart` — the app boots, all three tabs render, and
  creating a watchlist flows through to its empty state.

## A note on how this was verified

This project was written in a sandboxed cloud environment whose network
egress blocks `pub.dev`/`storage.googleapis.com`, so I was not able to run
`flutter pub get`, `flutter analyze`, or `flutter test` myself before
handing this off. I read every file back carefully and had a second pass
review it, but please run `flutter analyze` and `flutter test` as your first
step — if anything surfaces, it's a quick fix and I'm glad to make it.
