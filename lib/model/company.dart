import 'base_name_entity.dart';

class Company extends BaseNameEntity {
  final String? address;
  final String? phoneNumber;
  final String? email;
  final String? website;
  final String? logo;
  final String? taxNumber;
  final String? vatNumber;

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
    };
  }
}
