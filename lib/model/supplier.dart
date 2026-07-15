import 'package:isar/isar.dart';
import 'base_entity.dart';

part 'supplier.g.dart';

@collection
class Supplier extends BaseEntity {
  Id isarId = Isar.autoIncrement;
  final String name;
  final String? email;
  final String? phoneNumber;
  final String? address;
  final String? contactPerson;

  Supplier({
    super.id,
    super.dateCreated,
    super.dateModified,
    super.createdByName,
    super.modifiedByName,
    super.version,
    required this.name,
    this.email,
    this.phoneNumber,
    this.address,
    this.contactPerson,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id']?.toString(),
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
