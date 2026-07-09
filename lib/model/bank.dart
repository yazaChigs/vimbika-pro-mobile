import 'package:isar/isar.dart';
import 'package:vimbika_pro/model/base_name_entity.dart';
import 'package:vimbika_pro/model/currency.dart';

part 'bank.g.dart';

@collection
class Bank extends BaseNameEntity {
  Id isarId = Isar.autoIncrement;
  final currency = IsarLink<Currency>();
  String? accountNumber;
  String? branch;
  String? bankName;
  bool? isSystemCreated;

  Bank({
    super.id,
    super.dateCreated,
    super.dateModified,
    super.createdByName,
    super.modifiedByName,
    super.version,
    required super.name,
    super.description,
    this.accountNumber,
    this.branch,
    this.bankName,
    this.isSystemCreated,
    Currency? currency,
  }) {
    if (currency != null) {
      this.currency.value = currency;
    }
  }

  factory Bank.fromJson(Map<String, dynamic> json) {
    final bank = Bank(
      id: json['id']?.toString(),
      dateCreated: json['dateCreated'],
      dateModified: json['dateModified'],
      createdByName: json['createdByName'],
      modifiedByName: json['modifiedByName'],
      version: json['version'],
      name: json['name'] ?? '',
      description: json['description'],
      accountNumber: json['accountNumber'],
      branch: json['branch'],
      bankName: json['bankName'],
      isSystemCreated: json['isSystemCreated'],
    );

    if (json['currency'] != null) {
      bank.currency.value = Currency.fromJson(json['currency']);
    }

    return bank;
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
      'accountNumber': accountNumber,
      'branch': branch,
      'bankName': bankName,
      'isSystemCreated': isSystemCreated,
      'currency': currency.value?.toJson(),
    };
  }
}
