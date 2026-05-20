import 'base_name_entity.dart';
import 'currency.dart';
import 'bank.dart';

class PaymentType extends BaseNameEntity {
  final bool isCash;
  final bool isCard;
  final bool isMobileMoney;
  final bool isBankTransfer;
  final bool _isCredit; // Internal field
  final bool active; // Added active field
  final bool isSystemCreated;
  final Currency? currency;
  final List<Bank>? banks;

  bool get isCredit {
    if (_isCredit) return true;
    final upperName = name.toUpperCase();
    return upperName.startsWith('ACC-') || upperName.startsWith('CREDIT-');
  }

  PaymentType({
    String? id,
    String? dateCreated,
    String? dateModified,
    String? createdByName,
    String? modifiedByName,
    int? version,
    required String name,
    String? description,
    this.isCash = false,
    this.isCard = false,
    this.isMobileMoney = false,
    this.isBankTransfer = false,
    bool isCredit = false, // Initialize internal field
    this.active = true, // Default to true
    this.currency,
    this.banks,
    this.isSystemCreated = false,
  }) : _isCredit = isCredit,
       super(
          id: id,
          dateCreated: dateCreated,
          dateModified: dateModified,
          createdByName: createdByName,
          modifiedByName: modifiedByName,
          version: version,
          name: name,
          description: description,
        );

  PaymentType copyWith({
    String? id,
    String? dateCreated,
    String? dateModified,
    String? createdByName,
    String? modifiedByName,
    int? version,
    String? name,
    String? description,
    bool? isCash,
    bool? isCard,
    bool? isMobileMoney,
    bool? isBankTransfer,
    bool? isCredit,
    bool? active,
    bool? isSystemCreated,
    Currency? currency,
    List<Bank>? banks,
  }) {
    return PaymentType(
      id: id ?? this.id,
      dateCreated: dateCreated ?? this.dateCreated,
      dateModified: dateModified ?? this.dateModified,
      createdByName: createdByName ?? this.createdByName,
      modifiedByName: modifiedByName ?? this.modifiedByName,
      version: version ?? this.version,
      name: name ?? this.name,
      description: description ?? this.description,
      isCash: isCash ?? this.isCash,
      isCard: isCard ?? this.isCard,
      isMobileMoney: isMobileMoney ?? this.isMobileMoney,
      isBankTransfer: isBankTransfer ?? this.isBankTransfer,
      isCredit: isCredit ?? this._isCredit,
      active: active ?? this.active,
      currency: currency ?? this.currency,
      banks: banks ?? this.banks,
      isSystemCreated: isSystemCreated ?? this.isSystemCreated,
    );
  }

  factory PaymentType.fromJson(dynamic jsonData) {
    if (jsonData is String) {
      return PaymentType(
        id: jsonData,
        name: jsonData,
      );
    }
    
    final Map<String, dynamic> json = jsonData as Map<String, dynamic>;
    
    return PaymentType(
      id: json['id']?.toString(),
      dateCreated: json['dateCreated'] ,
      dateModified: json['dateModified'] ,
      createdByName: json['createdByName'] is Map ? json['createdByName']['name']?.toString() ?? json['createdByName']['firstName']?.toString() : json['createdByName']?.toString(),
      modifiedByName: json['modifiedByName'] is Map ? json['modifiedByName']['name']?.toString() ?? json['modifiedByName']['firstName']?.toString() : json['modifiedByName']?.toString(),
      version: json['version'] is int ? json['version'] : int.tryParse(json['version']?.toString() ?? ''),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      isCash: json['isCash'] == true || json['isCash'] == 'true',
      isCard: json['isCard'] == true || json['isCard'] == 'true',
      isMobileMoney: json['isMobileMoney'] == true || json['isMobileMoney'] == 'true',
      isBankTransfer: json['isBankTransfer'] == true || json['isBankTransfer'] == 'true',
      isCredit: json['isCredit'] == true || json['isCredit'] == 'true', // Parse isCredit from JSON
      active: json['active'] ?? true, // Parse active from JSON, default true
      currency: json['currency'] != null
          ? (json['currency'] is String ? Currency(id: json['currency']) : Currency.fromMap(json['currency']))
          : null,
      banks: json['banks'] != null
          ? (json['banks'] as List).map((i) => Bank.fromJson(i)).toList()
          : null,
      isSystemCreated: json['isSystemCreated'] ?? false,
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
      'description': description,
      'isCash': isCash,
      'isCard': isCard,
      'isMobileMoney': isMobileMoney,
      'isBankTransfer': isBankTransfer,
      'isCredit': _isCredit, // Save the actual boolean received from the API if it's there
      'active': active,
      'currency': currency?.toJson(),
      'banks': banks?.map((i) => i.toJson()).toList(),
      'isSystemCreated': isSystemCreated,
    };
  }
}
