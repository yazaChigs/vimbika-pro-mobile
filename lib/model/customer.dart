import 'base_entity.dart';
import 'customer_currency_amount.dart';
import 'company.dart';
import 'branch.dart';

class Customer extends BaseEntity {
  final String name;
  final String? email;
  final String? phoneNumber;
  final String? address;
  final String? accountNumber; 
  final String? taxNumber;
  final String? tinNumber;
  final List<CustomerCurrencyAmount>? currencyBalance;
  final Company? company;
  final Branch? branch;
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
    this.phoneNumber,
    this.address,
    this.currencyBalance,
    this.company,
    this.branch,
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

  Customer copyWith({
    String? id,
    String? dateCreated,
    String? dateModified,
    String? createdByName,
    String? modifiedByName,
    int? version,
    String? name,
    String? email,
    String? phoneNumber,
    String? address,
    String? accountNumber,
    String? taxNumber,
    String? tinNumber,
    List<CustomerCurrencyAmount>? currencyBalance,
    Company? company,
    Branch? branch,
    double? points,
    bool? isSynced,
  }) {
    return Customer(
      id: id ?? this.id,
      dateCreated: dateCreated ?? this.dateCreated,
      dateModified: dateModified ?? this.dateModified,
      createdByName: createdByName ?? this.createdByName,
      modifiedByName: modifiedByName ?? this.modifiedByName,
      version: version ?? this.version,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      accountNumber: accountNumber ?? this.accountNumber,
      taxNumber: taxNumber ?? this.taxNumber,
      tinNumber: tinNumber ?? this.tinNumber,
      currencyBalance: currencyBalance ?? this.currencyBalance,
      company: company ?? this.company,
      branch: branch ?? this.branch,
      isSynced: isSynced ?? this.isSynced,
      points: points ?? this.points,
    );
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id']?.toString(),
      dateCreated: json['dateCreated'], 
      dateModified: json['dateModified'], 
      createdByName: json['createdByName'],
      modifiedByName: json['modifiedByName'],
      version: json['version'],
      name: json['name'] ?? 'Unknown',
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      address: json['address'],
      accountNumber: json['accountNumber']?.toString(), 
      taxNumber: json['taxNumber']?.toString(),
      tinNumber: json['tinNumber']?.toString(),
      currencyBalance: (json['currencyBalance'] as List<dynamic>?)
          ?.map((e) => CustomerCurrencyAmount.fromJson(e as Map<String, dynamic>))
          .toList(),
      company: json['company'] != null ? Company.fromJson(json['company']) : null,
      branch: json['branch'] != null ? Branch.fromJson(json['branch']) : null,
      isSynced: json['isSynced'] ?? true, // Default to true for existing data
      points: json['points']?.toDouble() ?? 0.0,
    );
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
      'phoneNumber': phoneNumber,
      'address': address,
      'accountNumber': accountNumber,
      'taxNumber': taxNumber,
      'tinNumber': tinNumber,
      'currencyBalance':
          currencyBalance?.map((e) => e.toJson()).toList(),
      'company': company?.toJson(),
      'branch': branch?.toJson(),
      'isSynced': isSynced, // Include in JSON
      'points': points,
    };
  }
}
