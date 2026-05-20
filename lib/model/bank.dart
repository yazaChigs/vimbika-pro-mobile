import 'base_name_entity.dart';
import 'currency.dart';

class Bank extends BaseNameEntity {
  final String? accountNumber;
  final String? branch;
  final Currency? currency;
  bool? isSystemCreated;

  Bank({
    String? id,
    String? dateCreated,
    String? dateModified,
    String? createdByName,
    String? modifiedByName,
    int? version,
    required String name,
    String? description,
    this.accountNumber,
    this.branch,
    this.currency,
    this.isSystemCreated,
  }) : super(
          id: id,
          dateCreated: dateCreated,
          dateModified: dateModified,
          createdByName: createdByName,
          modifiedByName: modifiedByName,
          version: version,
          name: name,
          description: description,
        );

  factory Bank.fromJson(dynamic jsonData) {
    if (jsonData is String) {
      return Bank(
        id: jsonData,
        name: jsonData,
      );
    }

    final Map<String, dynamic> json = jsonData as Map<String, dynamic>;

    return Bank(
      id: json['id']?.toString(),
      dateCreated: json['dateCreated'] ,
      dateModified: json['dateModified'] ,
      createdByName: json['createdByName'] is Map ? json['createdByName']['name']?.toString() ?? json['createdByName']['firstName']?.toString() : json['createdByName']?.toString(),
      modifiedByName: json['modifiedByName'] is Map ? json['modifiedByName']['name']?.toString() ?? json['modifiedByName']['firstName']?.toString() : json['modifiedByName']?.toString(),
      version: json['version'] is int ? json['version'] : int.tryParse(json['version']?.toString() ?? ''),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      accountNumber: json['accountNumber']?.toString(),
      branch: json['branch']?.toString(),
      currency: json['currency'] != null
          ? (json['currency'] is String ? Currency(id: json['currency']) : Currency.fromMap(json['currency']))
          : null,
      isSystemCreated: json['isSystemCreated'] is bool ? json['isSystemCreated'] : false,
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
      'accountNumber': accountNumber,
      'branch': branch,
      'currency': currency?.toJson(),
      'isSystemCreated': isSystemCreated,
    };
  }
}
