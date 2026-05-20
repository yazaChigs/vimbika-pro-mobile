abstract class BaseEntity {
  final String? id;
  final String? dateCreated;
  final String? dateModified;
  final String? createdByName;
  final String? modifiedByName;
  final int? version;

  BaseEntity({
    this.id,
    this.dateCreated,
    this.dateModified,
    this.createdByName,
    this.modifiedByName,
    this.version,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BaseEntity &&
        runtimeType == other.runtimeType &&
        id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}
