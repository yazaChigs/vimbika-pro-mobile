import 'package:isar/isar.dart';
import 'package:vimbika_pro/model/currency.dart';

part 'customer_currency_amount.g.dart';

@collection
class CustomerCurrencyAmount {
  Id isarId = Isar.autoIncrement;
  final currency = IsarLink<Currency>();
  double balance;

  CustomerCurrencyAmount({
    Currency? currency,
    this.balance = 0.0,
  }) {
    if (currency != null) {
      this.currency.value = currency;
    }
  }

  factory CustomerCurrencyAmount.fromJson(Map<String, dynamic> json) {
    final item = CustomerCurrencyAmount(
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
    );
    if (json['currency'] != null) {
      item.currency.value = Currency.fromJson(json['currency']);
    }
    return item;
  }

  Map<String, dynamic> toJson() {
    return {
      'balance': balance,
      'currency': currency.value?.toJson(),
    };
  }

  CustomerCurrencyAmount copyWith({
    double? amount,
    Currency? currency,
    Id? isarId,
  }) {
    return CustomerCurrencyAmount(
      balance: amount ?? this.balance,
      currency: currency ?? this.currency.value,
    )..isarId = isarId ?? this.isarId;
  }
}
