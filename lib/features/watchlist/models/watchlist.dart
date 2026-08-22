import 'package:flutter/foundation.dart';

@immutable
class Watchlist {
  const Watchlist({
    required this.id,
    required this.name,
    required this.symbols,
  });

  final String id;
  final String name;

  /// Ordered list of stock symbols. Order is meaningful -- it's exactly
  /// what the user arranged via drag-to-reorder.
  final List<String> symbols;

  Watchlist copyWith({String? name, List<String>? symbols}) {
    return Watchlist(
      id: id,
      name: name ?? this.name,
      symbols: symbols ?? this.symbols,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'symbols': symbols,
      };

  factory Watchlist.fromJson(Map<dynamic, dynamic> json) {
    return Watchlist(
      id: json['id'] as String,
      name: json['name'] as String,
      symbols: List<String>.from(json['symbols'] as List),
    );
  }
}
