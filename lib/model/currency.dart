import 'package:isar/isar.dart';
import 'package:vimbika_pro/model/base_entity.dart';

part 'currency.g.dart';

@collection
class Currency extends BaseEntity {
  Id isarId = Isar.autoIncrement;
  String? name;
  String? code;
  String? symbol;
  bool? isBaseCurrency;
  double? rate;
  bool? isSystemCreated;

  Currency({
    String? id,
    String? dateCreated,
    String? dateModified,
    String? createdByName,
    String? modifiedByName,
    int? version,
    this.name,
    this.code,
    this.symbol,
    this.isBaseCurrency,
    this.rate,
    this.isSystemCreated,
  }) : super(
          id: id,
          dateCreated: dateCreated,
          dateModified: dateModified,
          createdByName: createdByName,
          modifiedByName: modifiedByName,
          version: version,
        );

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      id: json['id']?.toString(),
      dateCreated: json['dateCreated']?.toString(),
      dateModified: json['dateModified']?.toString(),
      createdByName: json['createdByName']?.toString(),
      modifiedByName: json['modifiedByName']?.toString(),
      version: json['version'] is int ? json['version'] : (json['version'] is num ? (json['version'] as num).toInt() : null),
      name: json['name']?.toString(),
      code: json['code']?.toString(),
      symbol: json['symbol']?.toString(),
      isBaseCurrency: json['isBaseCurrency'] as bool?,
      rate: (json['rate'] as num?)?.toDouble(),
      isSystemCreated: json['isSystemCreated'] as bool?,
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
      'code': code,
      'symbol': symbol,
      'isBaseCurrency': isBaseCurrency,
      'rate': rate,
      'isSystemCreated': isSystemCreated,
    };
  }

  Currency copyWith({
    String? id,
    String? dateCreated,
    String? dateModified,
    String? createdByName,
    String? modifiedByName,
    int? version,
    String? name,
    String? code,
    String? symbol,
    bool? isBaseCurrency,
    double? rate,
    bool? isSystemCreated,
  }) {
    return Currency(
      id: id ?? this.id,
      dateCreated: dateCreated ?? this.dateCreated,
      dateModified: dateModified ?? this.dateModified,
      createdByName: createdByName ?? this.createdByName,
      modifiedByName: modifiedByName ?? this.modifiedByName,
      version: version ?? this.version,
      name: name ?? this.name,
      code: code ?? this.code,
      symbol: symbol ?? this.symbol,
      isBaseCurrency: isBaseCurrency ?? this.isBaseCurrency,
      rate: rate ?? this.rate,
      isSystemCreated: isSystemCreated ?? this.isSystemCreated,
    );
  }
}
