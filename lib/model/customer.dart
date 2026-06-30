import 'package:isar/isar.dart';
import 'package:vimbika_pro/model/base_entity.dart';
import 'package:vimbika_pro/model/customer_currency_amount.dart';
import 'package:vimbika_pro/model/company.dart';
import 'package:vimbika_pro/model/branch.dart';

part 'customer.g.dart';

@collection
class Customer extends BaseEntity {
  Id isarId = Isar.autoIncrement;
  final String name;
  final String? email;
  final String? mobilePhone;
  final String? address;
  final String? accountNumber;
  final String? taxNumber;
  final String? tinNumber;
  final currencyBalance = IsarLinks<CustomerCurrencyAmount>();
  final company = IsarLink<Company>();
  final branch = IsarLink<Branch>();
  final bool isSynced; // New field
  final double points;

  Customer({
    String? id,
    String? dateCreated,
    String? dateModified,
    String? createdByName,
    String? modifiedByName,
    int? version,
    required this.name,
    this.accountNumber,
    this.taxNumber,
    this.tinNumber,
    this.email,
    this.mobilePhone,
    this.address,
    this.points = 0.0,
    this.isSynced = true, // Default to true
  }) : super(
          id: id,
          dateCreated: dateCreated,
          dateModified: dateModified,
          createdByName: createdByName,
          modifiedByName: modifiedByName,
          version: version,
        );

  factory Customer.fromJson(Map<String, dynamic> json) {
    final customer = Customer(
      id: json['id']?.toString(),
      dateCreated: json['dateCreated'],
      dateModified: json['dateModified'],
      createdByName: json['createdByName'],
      modifiedByName: json['modifiedByName'],
      version: json['version'],
      name: json['name'] ?? 'Unknown',
      email: json['email'],
      mobilePhone: json['mobilePhone'],
      address: json['address'],
      accountNumber: json['accountNumber']?.toString(),
      taxNumber: json['taxNumber']?.toString(),
      tinNumber: json['tinNumber']?.toString(),
      isSynced: json['isSynced'] ?? true, // Default to true for existing data
      points: json['points']?.toDouble() ?? 0.0,
    );

    if (json['currencyBalance'] != null) {
      customer.currencyBalance.addAll((json['currencyBalance'] as List<dynamic>?)
          ?.map((e) => CustomerCurrencyAmount.fromJson(e as Map<String, dynamic>))
          .toList() ?? []);
    }
    if (json['company'] != null) {
      customer.company.value = Company.fromJson(json['company']);
    }
    if (json['branch'] != null) {
      customer.branch.value = Branch.fromJson(json['branch']);
    }

    return customer;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateCreated': dateCreated,
      'dateModified': dateModified,
      'createdByName': createdByName,
      'modifiedByName': modifiedByName,
      'version': version,
      'name': name,
      'email': email,
      'mobilePhone': mobilePhone,
      'address': address,
      'accountNumber': accountNumber,
      'taxNumber': taxNumber,
      'tinNumber': tinNumber,
      'currencyBalance':
          currencyBalance.map((e) => e.toJson()).toList(),
      'company': company.value?.toJson(),
      'branch': branch.value?.toJson(),
      'isSynced': isSynced, // Include in JSON
      'points': points,
    };
  }

  Customer copyWith({
    String? id,
    String? dateCreated,
    String? dateModified,
    String? createdByName,
    String? modifiedByName,
    int? version,
    String? name,
    String? accountNumber,
    String? taxNumber,
    String? tinNumber,
    String? email,
    String? mobilePhone,
    String? address,
    double? points,
    bool? isSynced,
    Company? company,
    Branch? branch,
    List<CustomerCurrencyAmount>? currencyBalance,
  }) {
    final customer = Customer(
      id: id ?? this.id,
      dateCreated: dateCreated ?? this.dateCreated,
      dateModified: dateModified ?? this.dateModified,
      createdByName: createdByName ?? this.createdByName,
      modifiedByName: modifiedByName ?? this.modifiedByName,
      version: version ?? this.version,
      name: name ?? this.name,
      accountNumber: accountNumber ?? this.accountNumber,
      taxNumber: taxNumber ?? this.taxNumber,
      tinNumber: tinNumber ?? this.tinNumber,
      email: email ?? this.email,
      mobilePhone: mobilePhone ?? this.mobilePhone,
      address: address ?? this.address,
      points: points ?? this.points,
      isSynced: isSynced ?? this.isSynced,
    );
    customer.company.value = company ?? this.company.value;
    customer.branch.value = branch ?? this.branch.value;
    if (currencyBalance != null) {
      customer.currencyBalance.addAll(currencyBalance);
    } else {
      customer.currencyBalance.addAll(this.currencyBalance);
    }
    return customer;
  }
}
