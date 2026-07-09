import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:vimbika_pro/model/base_name_entity.dart';
import 'package:vimbika_pro/model/currency.dart';
import 'package:vimbika_pro/model/bank.dart';

part 'payment_type.g.dart';

@collection
class PaymentType extends BaseNameEntity {
  Id isarId = Isar.autoIncrement;
  final bool active;
  final bool isCash;
  final bool isCredit;
  final bool isCard;
  final bool isMobileMoney;
  final bool isBankTransfer;
  final bool? isSystemCreated;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final banks = IsarLinks<Bank>();

  @ignore
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<Bank> banksList = [];

  final currency = IsarLink<Currency>();

  PaymentType({
    super.id,
    super.dateCreated,
    super.dateModified,
    super.createdByName,
    super.modifiedByName,
    super.version,
    required super.name,
    super.description,
    this.active = true,
    this.isCash = false,
    this.isCredit = false,
    this.isCard = false,
    this.isMobileMoney = false,
    this.isBankTransfer = false,
    this.isSystemCreated,
    List<Bank>? banks,
    Currency? currency,
  }) : banksList = banks ?? [] {
    if (banks != null) {
      this.banks.addAll(banks);
    }
    if (currency != null) {
      this.currency.value = currency;
    }
  }

  @ignore
  List<Bank> get allBanks {
    if (banksList.isNotEmpty) return banksList;
    if (banks.isAttached) {
      banks.loadSync();
    }
    return banks.toList();
  }

  void syncListToIsarLinks() {
    if (banksList.isNotEmpty) {
      banks.clear();
      banks.addAll(banksList);
    }
  }

  PaymentType copyWith({
    String? id,
    String? dateCreated,
    String? dateModified,
    String? createdByName,
    String? modifiedByName,
    int? version,
    String? name,
    String? description,
    bool? active,
    bool? isCash,
    bool? isCredit,
    bool? isCard,
    bool? isMobileMoney,
    bool? isBankTransfer,
    bool? isSystemCreated,
    List<Bank>? banks,
    Currency? currency,
  }) {
    final newPaymentType = PaymentType(
      id: id ?? this.id,
      dateCreated: dateCreated ?? this.dateCreated,
      dateModified: dateModified ?? this.dateModified,
      createdByName: createdByName ?? this.createdByName,
      modifiedByName: modifiedByName ?? this.modifiedByName,
      version: version ?? this.version,
      name: name ?? this.name,
      description: description ?? this.description,
      active: active ?? this.active,
      isCash: isCash ?? this.isCash,
      isCredit: isCredit ?? this.isCredit,
      isCard: isCard ?? this.isCard,
      isMobileMoney: isMobileMoney ?? this.isMobileMoney,
      isBankTransfer: isBankTransfer ?? this.isBankTransfer,
      isSystemCreated: isSystemCreated ?? this.isSystemCreated,
      banks: banks ?? allBanks,
    );
    if (currency != null) {
      newPaymentType.currency.value = currency;
    } else {
      newPaymentType.currency.value = this.currency.value;
    }
    return newPaymentType;
  }

  factory PaymentType.fromJson(Map<String, dynamic> json) {
    final paymentType = PaymentType(
      id: json['id']?.toString(),
      dateCreated: json['dateCreated'],
      dateModified: json['dateModified'],
      createdByName: json['createdByName'],
      modifiedByName: json['modifiedByName'],
      version: json['version'],
      name: json['name'] ?? '',
      description: json['description'],
      active: json['active'] ?? true,
      isCash: json['isCash'] ?? false,
      isCredit: json['isCredit'] ?? false,
      isCard: json['isCard'] ?? false,
      isMobileMoney: json['isMobileMoney'] ?? false,
      isBankTransfer: json['isBankTransfer'] ?? false,
      isSystemCreated: json['isSystemCreated'],
      banks: json['banks'] != null
          ? (json['banks'] as List).map((i) => Bank.fromJson(i)).toList()
          : null,
    );

    if (json['currency'] != null) {
      paymentType.currency.value = Currency.fromJson(json['currency']);
    }

    return paymentType;
  }

  Map<String, dynamic> toJson() {
    if (currency.isAttached) currency.loadSync();
    return {
      'id': id,
      'dateCreated': dateCreated,
      'dateModified': dateModified,
      'createdByName': createdByName,
      'modifiedByName': modifiedByName,
      'version': version,
      'name': name,
      'description': description,
      'active': active,
      'isCash': isCash,
      'isCredit': isCredit,
      'isCard': isCard,
      'isMobileMoney': isMobileMoney,
      'isBankTransfer': isBankTransfer,
      'isSystemCreated': isSystemCreated,
      'banks': allBanks.map((b) => b.toJson()).toList(),
      'currency': currency.value?.toJson(),
    };
  }
}
