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
  
  // This field is for the Isar database relationship.
  @Name("currencyBalance")
  final currencyBalanceLinks = IsarLinks<CustomerCurrencyAmount>();
  
  // This field is used for JSON serialization and general app logic.
  // Isar will ignore it.
  @ignore
  List<CustomerCurrencyAmount> currencyBalance = [];

  final company = IsarLink<Company>();
  final branch = IsarLink<Branch>();
  final bool isSynced;
  final double points;
  final double balance;

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
    this.isSynced = true,
    this.balance = 0.0,
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
      dateCreated: json['dateCreated']?.toString(),
      dateModified: json['dateModified']?.toString(),
      createdByName: json['createdByName']?.toString(),
      modifiedByName: json['modifiedByName']?.toString(),
      version: json['version'] is int ? json['version'] : (json['version'] is num ? (json['version'] as num).toInt() : null),
      name: json['name']?.toString() ?? 'Unknown',
      email: json['email']?.toString(),
      mobilePhone: json['mobilePhone']?.toString(),
      address: json['address']?.toString(),
      accountNumber: json['accountNumber']?.toString(),
      taxNumber: json['taxNumber']?.toString(),
      tinNumber: json['tinNumber']?.toString(),
      isSynced: json['isSynced'] ?? true,
      points: (json['points'] as num?)?.toDouble() ?? 0.0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
    );

    // Deserialize from 'currencyBalance' (the API field) into our plain list.
    if (json['currencyBalance'] != null) {
      customer.currencyBalance = (json['currencyBalance'] as List<dynamic>?)
          ?.map((e) => CustomerCurrencyAmount.fromJson(e as Map<String, dynamic>))
          .toList() ?? [];
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
    if (company.isAttached) company.loadSync();
    if (branch.isAttached) branch.loadSync();
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
      // Serialize the plain list into the 'currencyBalance' field for the API.
      'currencyBalance': currencyBalance.map((e) => e.toJson()).toList(),
      'company': company.value?.toJson(),
      'branch': branch.value?.toJson(),
      'isSynced': isSynced,
      'points': points,
      'balance': balance,
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
    Id? isarId,
    double? balance,
  }) {
    final newCustomer = Customer(
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
      balance: balance ?? this.balance,
    );

    newCustomer.isarId = isarId ?? this.isarId;
    newCustomer.company.value = company ?? this.company.value;
    newCustomer.branch.value = branch ?? this.branch.value;
    
    // Deep copy the list to avoid shared state
    newCustomer.currencyBalance = currencyBalance ?? this.currencyBalance.map((e) => e.copyWith()).toList();

    // This ensures the Isar link is also kept in sync for objects already retrieved from Isar.
    if (this.currencyBalanceLinks.isNotEmpty) {
      newCustomer.currencyBalanceLinks.addAll(this.currencyBalanceLinks);
    }

    return newCustomer;
  }

  // Helper method to prepare for saving to Isar
  void syncListToIsarLinks() {
    currencyBalanceLinks.clear();
    currencyBalanceLinks.addAll(currencyBalance);
  }

  // Helper method to prepare for use in the app after loading from Isar
  void syncIsarLinksToList() {
    currencyBalance = currencyBalanceLinks.toList();
  }
}
