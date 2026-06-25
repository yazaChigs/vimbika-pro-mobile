import 'package:vimbika_pro/model/user.dart';

import 'base_name_entity.dart';

class Company extends BaseNameEntity {
  final String? address;
  final String? phoneNumber;
  final String? email;
  final String? website;
  final String? logo;
  final String? taxNumber;
  final String? vatNumber;
  final String? defaultBranch;
  final User? newOfflineUser;

  Company({
    String? id,
    String? dateCreated,
    String? dateModified,
    String? createdByName,
    String? modifiedByName,
    int? version,
    required String name,
    String? description,
    this.address,
    this.phoneNumber,
    this.email,
    this.website,
    this.logo,
    this.taxNumber,
    this.vatNumber,
    this.defaultBranch,
    this.newOfflineUser,
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

  Company copyWith({
    String? id,
    String? dateCreated,
    String? dateModified,
    String? createdByName,
    String? modifiedByName,
    int? version,
    String? name,
    String? description,
    String? address,
    String? phoneNumber,
    String? email,
    String? website,
    String? logo,
    String? taxNumber,
    String? vatNumber,
    String? defaultBranch,
    User? newOfflineUser,
  }) {
    return Company(
      id: id ?? this.id,
      dateCreated: dateCreated ?? this.dateCreated,
      dateModified: dateModified ?? this.dateModified,
      createdByName: createdByName ?? this.createdByName,
      modifiedByName: modifiedByName ?? this.modifiedByName,
      version: version ?? this.version,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      website: website ?? this.website,
      logo: logo ?? this.logo,
      taxNumber: taxNumber ?? this.taxNumber,
      vatNumber: vatNumber ?? this.vatNumber,
      newOfflineUser: newOfflineUser ?? this.newOfflineUser,
      defaultBranch: defaultBranch ?? this.defaultBranch,
    );
  }

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id']?.toString(),
      dateCreated: json['dateCreated'] ,
      dateModified: json['dateModified'] ,
      createdByName: json['createdByName']?.toString(),
      modifiedByName: json['modifiedByName']?.toString(),
      version: json['version'],
      name: json['name']?.toString() ?? 'Unknown Company',
      description: json['description']?.toString(),
      address: json['address']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      email: json['email']?.toString(),
      website: json['website']?.toString(),
      logo: json['logo']?.toString(),
      taxNumber: json['taxNumber']?.toString(),
      vatNumber: json['vatNumber']?.toString(),
      newOfflineUser: json['newOfflineUser'],
      defaultBranch: json['defaultBranch'],

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
      'address': address,
      'phoneNumber': phoneNumber,
      'email': email,
      'website': website,
      'logo': logo,
      'taxNumber': taxNumber,
      'vatNumber': vatNumber,
      'newOfflineUser': newOfflineUser,
      'defaultBranch': defaultBranch,
    };
  }
}
