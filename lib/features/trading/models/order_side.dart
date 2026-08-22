enum OrderSide {
  buy,
  sell;

  String get label => this == OrderSide.buy ? 'Buy' : 'Sell';

  String toJson() => name;

  static OrderSide fromJson(String value) => OrderSide.values.byName(value);
}
