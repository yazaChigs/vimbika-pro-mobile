import 'package:isar/isar.dart';
import 'package:vimbika_pro/model/base_name_entity.dart';

part 'unit.g.dart';

@collection
class Unit extends BaseNameEntity {
  Id isarId = Isar.autoIncrement;

  final String? abbreviation;

  Unit({
    super.id,
    super.dateCreated,
    super.dateModified,
    super.createdByName,
    super.modifiedByName,
    super.version,
    required super.name,
    this.abbreviation,
    super.description,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'],
      dateCreated: json['dateCreated'],
      dateModified: json['dateModified'],
      createdByName: json['createdByName'],
      modifiedByName: json['modifiedByName'],
      version: json['version'],
      name: json['name'],
      abbreviation: json['abbreviation'],
      description: json['description'],
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
      'abbreviation': abbreviation,
      'description': description,
    };
  }
}
