import 'base_entity.dart';

class Supplier extends BaseEntity {
  final String name;
  final String? email;
  final String? phoneNumber;
  final String? address;
  final String? contactPerson;

  Supplier({
    String? id,
    String? dateCreated,
    String? dateModified,
    String? createdByName,
    String? modifiedByName,
    int? version,
    required this.name,
    this.email,
    this.phoneNumber,
    this.address,
    this.contactPerson,
  }) : super(
          id: id,
          dateCreated: dateCreated,
          dateModified: dateModified,
          createdByName: createdByName,
          modifiedByName: modifiedByName,
          version: version,
        );

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'],
      dateCreated: json['dateCreated'] ,
      dateModified: json['dateModified'],
      createdByName: json['createdByName'],
      modifiedByName: json['modifiedByName'],
      version: json['version'],
      name: json['name'] ?? '',
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      address: json['address'],
      contactPerson: json['contactPerson'],
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
      'contactPerson': contactPerson,
    };
  }
}
