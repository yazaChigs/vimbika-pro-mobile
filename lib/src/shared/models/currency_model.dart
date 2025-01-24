import 'dart:convert';

CurrencyModel currencyModelFromJson(String str) => CurrencyModel.fromJson(json.decode(str));
String currencyItemModelToJson(CurrencyModel data) => json.encode(data.toJson());
class CurrencyModel {
  CurrencyModel({
    this.id,
    this.name,
    this.symbol,
    this.rate,
    this.isBaseCurrency

  });

  String? id;
  String? name;
  String? symbol;
  double? rate = 0.0;
  bool? isBaseCurrency = false;

  factory CurrencyModel.fromJson(String str) => CurrencyModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory CurrencyModel.fromMap(Map<String, dynamic> json) => CurrencyModel(
    id: json["id"],
    name: json["name"],
    symbol: json["symbol"],
    rate: json["rate"],
    isBaseCurrency: json["isBaseCurrency"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "name": name,
    "symbol": symbol,
    "rate": rate,
    "isBaseCurrency": isBaseCurrency,
  };
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is CurrencyModel &&
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