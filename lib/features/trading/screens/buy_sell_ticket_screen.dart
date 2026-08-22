import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/stock_catalog.dart';
import '../../../core/market/market_data_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../models/order_side.dart';
import '../state/trading_providers.dart';
import '../state/trading_service.dart';
import '../widgets/side_selector.dart';
import 'order_confirmation_screen.dart';

/// The Buy/Sell ticket. Always pre-filled for a single [symbol] -- opened
/// from a Watchlist row or a Holdings row, or directly for a quick trade.
class BuySellTicketScreen extends ConsumerStatefulWidget {
  const BuySellTicketScreen({super.key, required this.symbol, this.initialSide = OrderSide.buy});

  final String symbol;
  final OrderSide initialSide;

  @override
  ConsumerState<BuySellTicketScreen> createState() => _BuySellTicketScreenState();
}

class _BuySellTicketScreenState extends ConsumerState<BuySellTicketScreen> {
  late OrderSide _side = widget.initialSide;
  final TextEditingController _quantityController = TextEditingController();
  String? _quantityError;
  String? _submitError;
  bool _submitting = false;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _onQuantityChanged(String value) {
    setState(() {
      _quantityError = value.isEmpty ? null : Validators.quantityInput(value);
      _submitError = null;
    });
  }

  Future<void> _submit() async {
    final quantityError = Validators.quantityInput(_quantityController.text);
    if (quantityError != null) {
      setState(() => _quantityError = quantityError);
      return;
    }
    final quantity = Validators.parseQuantity(_quantityController.text)!;

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    // Execute at the LTP *at the moment of submission*, read fresh from
    // the feed right here rather than from any value captured earlier in
    // the widget's lifetime.
    final service = ref.read(marketDataServiceProvider);
    final ltp = service.currentPriceOf(widget.symbol);

    final result = ref.read(tradingServiceProvider).submit(
          symbol: widget.symbol,
          side: _side,
          quantity: quantity,
          ltpAtSubmission: ltp,
        );

    if (!mounted) return;

    if (result.isSuccess) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => OrderConfirmationScreen(order: result.order!)),
      );
    } else {
      setState(() {
        _submitting = false;
        _submitError = result.errorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = StockCatalog.byId(widget.symbol);
    final service = ref.watch(marketDataServiceProvider);
    final balance = ref.watch(walletControllerProvider);
    final holdings = ref.watch(holdingsControllerProvider);
    final holding = holdings.where((h) => h.symbol == widget.symbol).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: Text('${widget.symbol} · ${_side.label}')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(info.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Available balance: ${balance.format()}'
              '${holding != null ? '  ·  Held: ${holding.quantity} shares' : ''}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            ValueListenableBuilder(
              valueListenable: service.tickerFor(widget.symbol),
              builder: (context, tick, _) {
                final color = MarketColors.forChange(tick.isUp, isFlat: tick.change.isZero);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Live LTP', style: Theme.of(context).textTheme.bodySmall),
                            Text(
                              tick.ltp.format(),
                              style: priceTextStyle.copyWith(fontSize: 24),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(tick.change.formatSigned(), style: TextStyle(color: color)),
                            Text('${tick.changePercent.toStringAsFixed(2)}%', style: TextStyle(color: color)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            SideSelector(value: _side, onChanged: (side) => setState(() => _side = side)),
            const SizedBox(height: 20),
            TextField(
              controller: _quantityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
              decoration: InputDecoration(
                labelText: 'Quantity',
                errorText: _quantityError,
                suffixText: 'shares',
              ),
              onChanged: _onQuantityChanged,
            ),
            const SizedBox(height: 20),
            ValueListenableBuilder(
              valueListenable: service.tickerFor(widget.symbol),
              builder: (context, tick, _) {
                final quantity = int.tryParse(_quantityController.text.trim());
                final value = quantity != null && quantity > 0 ? tick.ltp * quantity : null;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Order value', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      value?.format() ?? '—',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ],
                );
              },
            ),
            if (_submitError != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _submitError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: _side == OrderSide.buy ? MarketColors.up : MarketColors.down,
                minimumSize: const Size.fromHeight(48),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text('${_side.label} ${widget.symbol}'),
            ),
          ],
        ),
      ),
    );
  }
}
