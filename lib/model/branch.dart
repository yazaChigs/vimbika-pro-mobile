import 'package:isar/isar.dart';
import 'package:vimbika_pro/model/base_entity.dart';
import 'package:vimbika_pro/model/company.dart';

part 'branch.g.dart';

@collection
class Branch extends BaseEntity {
  Id isarId = Isar.autoIncrement;
  String? name;
  String? description;
  String? address;
  String? phoneNumber;
  String? email;
  final company = IsarLink<Company>();

  Branch({
    String? id,
    String? dateCreated,
    String? dateModified,
    String? createdByName,
    String? modifiedByName,
    int? version,
    this.name,
    this.description,
    this.address,
    this.phoneNumber,
    this.email,
  }) : super(
          id: id,
          dateCreated: dateCreated,
          dateModified: dateModified,
          createdByName: createdByName,
          modifiedByName: modifiedByName,
          version: version,
        );

  factory Branch.fromJson(Map<String, dynamic> json) {
    final branch = Branch(
      id: json['id'],
      dateCreated: json['dateCreated'],
      dateModified: json['dateModified'],
      createdByName: json['createdByName'],
      modifiedByName: json['modifiedByName'],
      version: json['version'],
      name: json['name'],
      description: json['description'],
      address: json['address'],
      phoneNumber: json['phoneNumber'],
      email: json['email'],
    );

    if (json['company'] != null) {
      branch.company.value = Company.fromJson(json['company']);
    }

    return branch;
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
      'company': company.isLoaded ? company.value?.toJson() : null,
    };
  }
}
