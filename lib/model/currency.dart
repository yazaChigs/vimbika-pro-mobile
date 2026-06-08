import 'dart:convert';

Currency currencyModelFromJson(String str) => Currency.fromJson(json.decode(str));
String currencyItemModelToJson(Currency data) => json.encode(data.toMap());

class Currency {
  Currency({
    this.id,
    this.name,
    this.symbol,
    this.rate,
    this.isBaseCurrency,
    bool? isSystemCreated,
  });

  String? id;
  String? name;
  String? symbol;
  double? rate = 0.0;
  bool? isBaseCurrency = false;
  bool? isSystemCreated = false;

  Currency copyWith({
    String? id,
    String? name,
    String? symbol,
    double? rate,
    bool? isBaseCurrency,
    bool? isSystemCreated,
  }) {
    return Currency(
      id: id ?? this.id,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      rate: rate ?? this.rate,
      isBaseCurrency: isBaseCurrency ?? this.isBaseCurrency,
      isSystemCreated: isSystemCreated ?? this.isSystemCreated,
    );
  }

  /// Factory to create a Currency object from a decoded JSON map.
  /// This factory expects a Map<String, dynamic> as input.
  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency.fromMap(json);
  }

  factory Currency.fromRawJson(String str) => Currency.fromJson(json.decode(str));

  /// Returns a Map for JSON serialization (not a String)
  Map<String, dynamic> toJson() => toMap();

  factory Currency.fromMap(Map<String, dynamic> json) => Currency(
    id: json["id"]?.toString(),
    name: json["name"]?.toString(),
    symbol: json["symbol"]?.toString(),
    rate: (json["rate"] as num?)?.toDouble() ?? 0.0,
    isBaseCurrency: json["isBaseCurrency"] == true || json["isBaseCurrency"] == 'true',
    isSystemCreated: json["isSystemCreated"] == true || json["isSystemCreated"] == 'true',
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "name": name,
    "symbol": symbol,
    "rate": rate,
    "isBaseCurrency": isBaseCurrency,
    "isSystemCreated": isSystemCreated,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Currency &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              name == other.name &&
              symbol == other.symbol &&
              rate == other.rate &&
              isBaseCurrency == other.isBaseCurrency;

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ symbol.hashCode ^ rate.hashCode ^ isBaseCurrency.hashCode;
}
