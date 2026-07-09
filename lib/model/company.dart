import 'package:isar/isar.dart';
import 'package:vimbika_pro/model/base_entity.dart';

part 'company.g.dart';

@collection
class Company extends BaseEntity {
  Id isarId = Isar.autoIncrement;
  String? name;
  String? description;
  String? address;
  String? phoneNumber;
  String? email;
  String? website;
  String? logo;

  Company({
    super.id,
    super.dateCreated,
    super.dateModified,
    super.createdByName,
    super.modifiedByName,
    super.version,
    this.name,
    this.description,
    this.address,
    this.phoneNumber,
    this.email,
    this.website,
    this.logo,
  });

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
    String? defaultBranch,
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
    );
  }

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id']?.toString(),
      dateCreated: json['dateCreated']?.toString(),
      dateModified: json['dateModified']?.toString(),
      createdByName: json['createdByName']?.toString(),
      modifiedByName: json['modifiedByName']?.toString(),
      version: json['version'] is int ? json['version'] : (json['version'] is num ? (json['version'] as num).toInt() : null),
      name: json['name']?.toString(),
      description: json['description']?.toString(),
      address: json['address']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      email: json['email']?.toString(),
      website: json['website']?.toString(),
      logo: json['logo']?.toString(),
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
    };
  }
}
