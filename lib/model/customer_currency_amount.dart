import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:vimbika_pro/model/currency.dart';

part 'customer_currency_amount.g.dart';

@collection
class CustomerCurrencyAmount {
  Id isarId = Isar.autoIncrement;
  final currency = IsarLink<Currency>();
  double amount;

  CustomerCurrencyAmount({
    Currency? currency,
    this.amount = 0.0,
  }) {
    if (currency != null) {
      this.currency.value = currency;
    }
  }

  factory CustomerCurrencyAmount.fromJson(Map<String, dynamic> json) {
    final item = CustomerCurrencyAmount(
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
    if (json['currency'] != null) {
      item.currency.value = Currency.fromJson(json['currency']);
    }
    return item;
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency': currency.value?.toJson(),
    };
  }

  CustomerCurrencyAmount copyWith({
    double? amount,
  }) {
    return CustomerCurrencyAmount(
      amount: amount ?? this.amount,
    )..currency.value = currency.value;
  }
}
