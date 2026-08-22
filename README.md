# Trading App — Flutter Assignment

A mock trading app built in Flutter covering four features:

1. **Watchlist** — create and manage multiple watchlists with live prices
2. **Live Market** — continuously updating market overview for 10 stocks
3. **Buy / Sell Ticket** — place simulated orders against a wallet balance
4. **Holdings** — live P&L portfolio view with sorting and aggregate summary

No real backend. A single in-app mock market-data feed (`MarketDataService`) is the one source of price data for every screen.

---

## Prerequisites

| Tool | Minimum version | How to check |
|---|---|---|
| Flutter (stable channel) | 3.19 | `flutter --version` |
| Dart | 3.3 | bundled with Flutter |
| Android Studio / Xcode | any recent | for emulator/simulator |
| Git | any | `git --version` |

> **Don't have Flutter yet?**  
> Follow the official install guide: <https://docs.flutter.dev/get-started/install>  
> Make sure `flutter doctor` shows no critical issues before proceeding.

---

## Quick start (step by step)

### 1 — Clone the repository

```bash
git clone https://github.com/<your-username>/trading_app.git
cd trading_app
```

### 2 — Install dependencies

```bash
flutter pub get
```

### 3 — Choose a target and run

**Web (fastest, no emulator needed):**

```bash
flutter run -d chrome
```

**Android emulator:**

First, start an emulator from Android Studio (Device Manager → ▶ Play) or from the terminal:

```bash
flutter emulators --launch <emulator_id>   # list with: flutter emulators
```

Then run:

```bash
flutter run -d emulator-5554   # or: flutter run  (auto-picks the only device)
```

**iOS simulator (macOS only):**

```bash
open -a Simulator
flutter run -d iPhone\ 15    # or: flutter run -d <simulator-name>
```

**List all connected devices / emulators:**

```bash
flutter devices
```

### 4 — Run the tests

```bash
flutter test
```

### 5 — Check for lint issues

```bash
flutter analyze
```

---

## Walkthrough of each feature

### Feature 1 — Watchlists tab

- Tap **New watchlist** → enter a name → watchlist opens immediately
- Tap **+** (FAB) inside a watchlist → pick stocks from the bottom sheet
- **Swipe left** on a stock row to remove it
- **Drag** the handle on the right to reorder
- **Long-press** the ⋮ menu on the list screen to rename or delete a watchlist
- Tap any stock row → opens the Buy / Sell ticket pre-filled for that stock
- Restart the app — all watchlists and their order are restored from disk

### Feature 2 — Market tab (Live Prices)

- Shows live prices for all 10 stocks with **green flash (up) / red flash (down)** on every tick
- Tap the **tune icon** (top right) to open the tick-rate slider
  - Default: 1 tick / sec / stock
  - "Stress test" button → 5 ticks / sec / stock (50 total) — the UI stays smooth
- Tap any row → opens the Buy / Sell ticket

### Feature 3 — Buy / Sell ticket

- Opened from a Watchlist row, Market row, or Holdings row
- Live LTP updates in real time while the form is open
- **Order value** (qty × LTP) recomputes on every tick and on every keystroke
- Validation blocks submit for: empty quantity, fractional, zero, negative, oversized, insufficient balance, more shares than held
- On success → Order Confirmation screen → tap **View holdings** or **Done**

### Feature 4 — Holdings tab

- Shows every position with: symbol, quantity, avg cost, live LTP, current value, P&L (₹ and %)
- **Portfolio summary card** at the top shows total invested, current value, and total P&L — always equal to the sum of individual rows
- **Sort** via the ≡ icon: by P&L (default), by symbol, by current value
- Tap the **receipt icon** to open Order History
- Tap any row → opens the Buy / Sell ticket (pre-filled to Sell)
- Restart the app — holdings and wallet balance are restored from disk

---

## The 10 stocks

`RELIANCE, TCS, INFY, HDFCBANK, ICICIBANK, SBIN, ITC, LT, BHARTIARTL, AXISBANK`

Defined once in `lib/core/constants/stock_catalog.dart` with plausible starting prices. Used everywhere else by symbol.

---

## Project structure

```
lib/
  core/
    constants/stock_catalog.dart      fixed universe of 10 stocks + starting prices
    market/                            mock market-data feed (see below)
    persistence/app_database.dart      single Hive box + key registry
    theme/                             colors, text styles
    utils/                             Money, validators, id generator, formatters
  features/
    watchlist/                         Feature 1 — Watchlists
    market_overview/                   Feature 2 — Live Market
    trading/                           Features 3 & 4 — Buy/Sell + Holdings
    home/                              bottom-nav shell
  shared/widgets/
    flashing_tick_builder.dart         shared live-price + flash primitive
    empty_state.dart
test/
  core/                                unit tests: Money, market feed, validators
  features/                            unit tests: trading rules, watchlist CRUD
  widget_smoke_test.dart               widget test: app boots, tabs render, create watchlist
```

---

## Architecture

**State management: Riverpod.** Each feature owns a `StateNotifier` backed by a Hive repository. Business logic stays out of widgets and is easy to unit-test.

**Why Buy/Sell and Holdings share one `trading/` feature:** both operate on the same three pieces of state — wallet balance, holdings, order history — and `TradingService.submit()` is the single place that validates and mutates all three atomically.

### Mock market-data feed

- One `ValueNotifier<Tick>` per symbol, shared across the entire app. Two watchlists containing the same stock show identical prices by construction, not by synchronization.
- One independent `Timer` per symbol, so the configured ticks/sec is literal.
- `FlashingTickBuilder` subscribes to one symbol's notifier and rebuilds only that row/cell per tick — never a sibling or a parent `ListView`.
- Random walk with light mean-reversion toward the session open price and a 50%–200% floor/ceiling clamp, so prices move realistically without drifting to zero.
- Tick rate is configurable at runtime from the **Market** tab's tune icon.

### Money handling

`Money` stores an integer number of **paise** (1 rupee = 100 paise). All arithmetic is integer — `10.10 + 0.20` is exactly `10.30`. The only `double` allowed near money is a derived percentage for display, which is never fed back into a `Money` value.

### Holdings sort + live P&L

Each `HoldingRow` binds directly to its symbol's ticker so P&L updates every tick without the list rebuilding. Sort order recomputes on a throttled ~500ms cadence (plus immediately on any buy/sell) so a row crossing from loss to gain reorders in well under a second without the list resorting 50 times a second.

### Persistence

Single Hive box, one key per collection (`watchlists_v1`, `wallet_balance_paise_v1`, `holdings_v1`, `orders_v1`), each storing plain JSON-friendly maps/lists. No `build_runner` codegen step required — the app runs with `flutter pub get && flutter run` and nothing else.

---

## Feature → code map

| Feature | Screens | State |
|---|---|---|
| 1. Watchlist | `features/watchlist/screens/*` | `WatchlistController` |
| 2. Live Prices | `features/market_overview/screens/market_overview_screen.dart` | `MarketDataService` |
| 3. Buy / Sell | `features/trading/screens/buy_sell_ticket_screen.dart`, `order_confirmation_screen.dart`, `order_history_screen.dart` | `TradingService` + `WalletController` / `HoldingsController` / `OrderHistoryController` |
| 4. Holdings | `features/trading/screens/holdings_screen.dart` | same trading state, read-only here |

---

## Test coverage

```
flutter test
```

| File | What it covers |
|---|---|
| `test/core/money_test.dart` | Exact decimal arithmetic, formatting, no float drift |
| `test/core/market_data_service_test.dart` | Seeding, tick rate, price bounds, multi-reader agreement |
| `test/core/validators_test.dart` | All quantity edge cases (empty / fractional / zero / negative / oversized) |
| `test/features/trading/trading_service_test.dart` | Buy/sell math, weighted avg cost, balance/oversell rejection, order history ordering |
| `test/features/watchlist/watchlist_controller_test.dart` | CRUD, reorder, shared-symbol independence, persistence round-trip |
| `test/widget_smoke_test.dart` | App boots, all 3 tabs render, create-watchlist flow |
