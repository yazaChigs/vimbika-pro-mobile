import 'currency.dart';
import 'base_entity.dart';

class CustomerCurrencyAmount implements BaseEntity {
  @override
  final String? id;
  final double? balance;
  final Currency? currency;
  final DateTime? lastTranxDate;

  // BaseEntity fields
  final String? dateCreated;
  final String? dateModified;
  final String? createdByName;
  final String? modifiedByName;
  final int? version;

  CustomerCurrencyAmount({
    this.id,
    this.balance = 0.0,
    this.currency,
    this.lastTranxDate,
    // BaseEntity fields
    this.dateCreated,
    this.dateModified,
    this.createdByName,
    this.modifiedByName,
    this.version,
  });

  factory CustomerCurrencyAmount.fromJson(Map<String, dynamic> json) {
    return CustomerCurrencyAmount(
      id: json['id']?.toString(),
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] != null ? Currency.fromJson(json['currency']) : null,
      lastTranxDate: json['lastTranxDate'] != null ? _parseDateTime(json['lastTranxDate']) : null,
      // BaseEntity fields
      dateCreated: json['dateCreated'] ,
      dateModified: json['dateModified'] ,
      createdByName: json['createdByName']?.toString(),
      modifiedByName: json['modifiedByName']?.toString(),
      version: (json['version'] as num?)?.toInt(),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString().replaceAll(' ', 'T'));
    } catch (e) {
      return DateTime.tryParse(value.toString());
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'balance': balance,
      'currency': currency?.toJson(),
      'lastTranxDate': lastTranxDate?.toIso8601String(),
      // BaseEntity fields
      'dateCreated': dateCreated,
      'dateModified': dateModified,
      'createdByName': createdByName,
      'modifiedByName': modifiedByName,
      'version': version,
    };
  }
}
