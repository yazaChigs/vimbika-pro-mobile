// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSaleCollection on Isar {
  IsarCollection<Sale> get sales => this.collection();
}

const SaleSchema = CollectionSchema(
  name: r'Sale',
  id: 2760258395233294300,
  properties: {
    r'amountAfterDiscount': PropertySchema(
      id: 0,
      name: r'amountAfterDiscount',
      type: IsarType.double,
    ),
    r'amountPaid': PropertySchema(
      id: 1,
      name: r'amountPaid',
      type: IsarType.double,
    ),
    r'amountTendered': PropertySchema(
      id: 2,
      name: r'amountTendered',
      type: IsarType.double,
    ),
    r'amtToAcc': PropertySchema(
      id: 3,
      name: r'amtToAcc',
      type: IsarType.string,
    ),
    r'baseSaleAmount': PropertySchema(
      id: 4,
      name: r'baseSaleAmount',
      type: IsarType.double,
    ),
    r'cashierFullName': PropertySchema(
      id: 5,
      name: r'cashierFullName',
      type: IsarType.string,
    ),
    r'change': PropertySchema(
      id: 6,
      name: r'change',
      type: IsarType.double,
    ),
    r'createdByName': PropertySchema(
      id: 7,
      name: r'createdByName',
      type: IsarType.string,
    ),
    r'customerAccBankType': PropertySchema(
      id: 8,
      name: r'customerAccBankType',
      type: IsarType.string,
    ),
    r'dateCreated': PropertySchema(
      id: 9,
      name: r'dateCreated',
      type: IsarType.string,
    ),
    r'dateModified': PropertySchema(
      id: 10,
      name: r'dateModified',
      type: IsarType.string,
    ),
    r'fiscalized': PropertySchema(
      id: 11,
      name: r'fiscalized',
      type: IsarType.bool,
    ),
    r'id': PropertySchema(
      id: 12,
      name: r'id',
      type: IsarType.string,
    ),
    r'isSynced': PropertySchema(
      id: 13,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'kotNumber': PropertySchema(
      id: 14,
      name: r'kotNumber',
      type: IsarType.long,
    ),
    r'modifiedByName': PropertySchema(
      id: 15,
      name: r'modifiedByName',
      type: IsarType.string,
    ),
    r'posReference': PropertySchema(
      id: 16,
      name: r'posReference',
      type: IsarType.string,
    ),
    r'receiptQrCode': PropertySchema(
      id: 17,
      name: r'receiptQrCode',
      type: IsarType.string,
    ),
    r'receiptQrData': PropertySchema(
      id: 18,
      name: r'receiptQrData',
      type: IsarType.string,
    ),
    r'referenceNumber': PropertySchema(
      id: 19,
      name: r'referenceNumber',
      type: IsarType.string,
    ),
    r'saleStatus': PropertySchema(
      id: 20,
      name: r'saleStatus',
      type: IsarType.string,
    ),
    r'shiftReference': PropertySchema(
      id: 21,
      name: r'shiftReference',
      type: IsarType.string,
    ),
    r'taxInvoice': PropertySchema(
      id: 22,
      name: r'taxInvoice',
      type: IsarType.bool,
    ),
    r'ticketName': PropertySchema(
      id: 23,
      name: r'ticketName',
      type: IsarType.string,
    ),
    r'timeCompleted': PropertySchema(
      id: 24,
      name: r'timeCompleted',
      type: IsarType.string,
    ),
    r'timeIniated': PropertySchema(
      id: 25,
      name: r'timeIniated',
      type: IsarType.string,
    ),
    r'totalDiscount': PropertySchema(
      id: 26,
      name: r'totalDiscount',
      type: IsarType.double,
    ),
    r'totalQuantity': PropertySchema(
      id: 27,
      name: r'totalQuantity',
      type: IsarType.double,
    ),
    r'totalTaxAmount': PropertySchema(
      id: 28,
      name: r'totalTaxAmount',
      type: IsarType.double,
    ),
    r'version': PropertySchema(
      id: 29,
      name: r'version',
      type: IsarType.long,
    )
  },
  estimateSize: _saleEstimateSize,
  serialize: _saleSerialize,
  deserialize: _saleDeserialize,
  deserializeProp: _saleDeserializeProp,
  idName: r'isarId',
  indexes: {},
  links: {
    r'customer': LinkSchema(
      id: -8715287472270872159,
      name: r'customer',
      target: r'Customer',
      single: true,
    ),
    r'company': LinkSchema(
      id: -5213353464575429214,
      name: r'company',
      target: r'Company',
      single: true,
    ),
    r'branch': LinkSchema(
      id: 2025681876999700403,
      name: r'branch',
      target: r'Branch',
      single: true,
    ),
    r'items': LinkSchema(
      id: -842299239162002906,
      name: r'items',
      target: r'SaleItem',
      single: false,
    ),
    r'paymentTypes': LinkSchema(
      id: 165356385027336449,
      name: r'paymentTypes',
      target: r'PaymentReceived',
      single: false,
    ),
    r'currency': LinkSchema(
      id: -4478176339807430413,
      name: r'currency',
      target: r'Currency',
      single: true,
    ),
    r'baseCurrency': LinkSchema(
      id: 827849800084562049,
      name: r'baseCurrency',
      target: r'Currency',
      single: true,
    )
  },
  embeddedSchemas: {},
  getId: _saleGetId,
  getLinks: _saleGetLinks,
  attach: _saleAttach,
  version: '3.1.0+1',
);

int _saleEstimateSize(
  Sale object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.amtToAcc;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.cashierFullName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.createdByName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.customerAccBankType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.dateCreated;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.dateModified;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.id;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.modifiedByName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.posReference;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.receiptQrCode;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.receiptQrData;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.referenceNumber;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.saleStatus;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.shiftReference;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.ticketName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.timeCompleted;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.timeIniated;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _saleSerialize(
  Sale object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.amountAfterDiscount);
  writer.writeDouble(offsets[1], object.amountPaid);
  writer.writeDouble(offsets[2], object.amountTendered);
  writer.writeString(offsets[3], object.amtToAcc);
  writer.writeDouble(offsets[4], object.baseSaleAmount);
  writer.writeString(offsets[5], object.cashierFullName);
  writer.writeDouble(offsets[6], object.change);
  writer.writeString(offsets[7], object.createdByName);
  writer.writeString(offsets[8], object.customerAccBankType);
  writer.writeString(offsets[9], object.dateCreated);
  writer.writeString(offsets[10], object.dateModified);
  writer.writeBool(offsets[11], object.fiscalized);
  writer.writeString(offsets[12], object.id);
  writer.writeBool(offsets[13], object.isSynced);
  writer.writeLong(offsets[14], object.kotNumber);
  writer.writeString(offsets[15], object.modifiedByName);
  writer.writeString(offsets[16], object.posReference);
  writer.writeString(offsets[17], object.receiptQrCode);
  writer.writeString(offsets[18], object.receiptQrData);
  writer.writeString(offsets[19], object.referenceNumber);
  writer.writeString(offsets[20], object.saleStatus);
  writer.writeString(offsets[21], object.shiftReference);
  writer.writeBool(offsets[22], object.taxInvoice);
  writer.writeString(offsets[23], object.ticketName);
  writer.writeString(offsets[24], object.timeCompleted);
  writer.writeString(offsets[25], object.timeIniated);
  writer.writeDouble(offsets[26], object.totalDiscount);
  writer.writeDouble(offsets[27], object.totalQuantity);
  writer.writeDouble(offsets[28], object.totalTaxAmount);
  writer.writeLong(offsets[29], object.version);
}

Sale _saleDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Sale(
    amountAfterDiscount: reader.readDoubleOrNull(offsets[0]),
    amountPaid: reader.readDoubleOrNull(offsets[1]),
    amountTendered: reader.readDoubleOrNull(offsets[2]),
    amtToAcc: reader.readStringOrNull(offsets[3]),
    baseSaleAmount: reader.readDoubleOrNull(offsets[4]),
    cashierFullName: reader.readStringOrNull(offsets[5]),
    change: reader.readDoubleOrNull(offsets[6]),
    createdByName: reader.readStringOrNull(offsets[7]),
    customerAccBankType: reader.readStringOrNull(offsets[8]),
    dateCreated: reader.readStringOrNull(offsets[9]),
    dateModified: reader.readStringOrNull(offsets[10]),
    fiscalized: reader.readBoolOrNull(offsets[11]),
    id: reader.readStringOrNull(offsets[12]),
    isSynced: reader.readBoolOrNull(offsets[13]) ?? false,
    kotNumber: reader.readLongOrNull(offsets[14]),
    modifiedByName: reader.readStringOrNull(offsets[15]),
    posReference: reader.readStringOrNull(offsets[16]),
    receiptQrCode: reader.readStringOrNull(offsets[17]),
    receiptQrData: reader.readStringOrNull(offsets[18]),
    referenceNumber: reader.readStringOrNull(offsets[19]),
    saleStatus: reader.readStringOrNull(offsets[20]),
    shiftReference: reader.readStringOrNull(offsets[21]),
    taxInvoice: reader.readBoolOrNull(offsets[22]),
    ticketName: reader.readStringOrNull(offsets[23]),
    timeCompleted: reader.readStringOrNull(offsets[24]),
    timeIniated: reader.readStringOrNull(offsets[25]),
    totalDiscount: reader.readDoubleOrNull(offsets[26]),
    totalQuantity: reader.readDoubleOrNull(offsets[27]),
    totalTaxAmount: reader.readDoubleOrNull(offsets[28]),
    version: reader.readLongOrNull(offsets[29]),
  );
  object.isarId = id;
  return object;
}

P _saleDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleOrNull(offset)) as P;
    case 1:
      return (reader.readDoubleOrNull(offset)) as P;
    case 2:
      return (reader.readDoubleOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readDoubleOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readDoubleOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readBoolOrNull(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 14:
      return (reader.readLongOrNull(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    case 16:
      return (reader.readStringOrNull(offset)) as P;
    case 17:
      return (reader.readStringOrNull(offset)) as P;
    case 18:
      return (reader.readStringOrNull(offset)) as P;
    case 19:
      return (reader.readStringOrNull(offset)) as P;
    case 20:
      return (reader.readStringOrNull(offset)) as P;
    case 21:
      return (reader.readStringOrNull(offset)) as P;
    case 22:
      return (reader.readBoolOrNull(offset)) as P;
    case 23:
      return (reader.readStringOrNull(offset)) as P;
    case 24:
      return (reader.readStringOrNull(offset)) as P;
    case 25:
      return (reader.readStringOrNull(offset)) as P;
    case 26:
      return (reader.readDoubleOrNull(offset)) as P;
    case 27:
      return (reader.readDoubleOrNull(offset)) as P;
    case 28:
      return (reader.readDoubleOrNull(offset)) as P;
    case 29:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _saleGetId(Sale object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _saleGetLinks(Sale object) {
  return [
    object.customer,
    object.company,
    object.branch,
    object.items,
    object.paymentTypes,
    object.currency,
    object.baseCurrency
  ];
}

void _saleAttach(IsarCollection<dynamic> col, Id id, Sale object) {
  object.isarId = id;
  object.customer.attach(col, col.isar.collection<Customer>(), r'customer', id);
  object.company.attach(col, col.isar.collection<Company>(), r'company', id);
  object.branch.attach(col, col.isar.collection<Branch>(), r'branch', id);
  object.items.attach(col, col.isar.collection<SaleItem>(), r'items', id);
  object.paymentTypes
      .attach(col, col.isar.collection<PaymentReceived>(), r'paymentTypes', id);
  object.currency.attach(col, col.isar.collection<Currency>(), r'currency', id);
  object.baseCurrency
      .attach(col, col.isar.collection<Currency>(), r'baseCurrency', id);
}

extension SaleQueryWhereSort on QueryBuilder<Sale, Sale, QWhere> {
  QueryBuilder<Sale, Sale, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SaleQueryWhere on QueryBuilder<Sale, Sale, QWhereClause> {
  QueryBuilder<Sale, Sale, QAfterWhereClause> isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterWhereClause> isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Sale, Sale, QAfterWhereClause> isarIdGreaterThan(Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<Sale, Sale, QAfterWhereClause> isarIdLessThan(Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<Sale, Sale, QAfterWhereClause> isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension SaleQueryFilter on QueryBuilder<Sale, Sale, QFilterCondition> {
  QueryBuilder<Sale, Sale, QAfterFilterCondition> amountAfterDiscountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'amountAfterDiscount',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition>
      amountAfterDiscountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'amountAfterDiscount',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> amountAfterDiscountEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amountAfterDiscount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition>
      amountAfterDiscountGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'amountAfterDiscount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> amountAfterDiscountLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'amountAfterDiscount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> amountAfterDiscountBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'amountAfterDiscount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> amountPaidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'amountPaid',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> amountPaidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'amountPaid',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> amountPaidEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amountPaid',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> amountPaidGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'amountPaid',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> amountPaidLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'amountPaid',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> amountPaidBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'amountPaid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> amountTenderedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'amountTendered',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> amountTenderedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'amountTendered',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> amountTenderedEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amountTendered',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> amountTenderedGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'amountTendered',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> amountTenderedLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'amountTendered',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> amountTenderedBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'amountTendered',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> amtToAccIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'amtToAcc',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> amtToAccIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'amtToAcc',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> amtToAccEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amtToAcc',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> amtToAccGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'amtToAcc',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> amtToAccLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'amtToAcc',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> amtToAccBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'amtToAcc',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> amtToAccStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'amtToAcc',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> amtToAccEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'amtToAcc',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> amtToAccContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'amtToAcc',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> amtToAccMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'amtToAcc',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> amtToAccIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amtToAcc',
        value: '',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> amtToAccIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'amtToAcc',
        value: '',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> baseSaleAmountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'baseSaleAmount',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> baseSaleAmountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'baseSaleAmount',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> baseSaleAmountEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'baseSaleAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> baseSaleAmountGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'baseSaleAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> baseSaleAmountLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'baseSaleAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> baseSaleAmountBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'baseSaleAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> cashierFullNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cashierFullName',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> cashierFullNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cashierFullName',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> cashierFullNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cashierFullName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> cashierFullNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cashierFullName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> cashierFullNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cashierFullName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> cashierFullNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cashierFullName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> cashierFullNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cashierFullName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> cashierFullNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cashierFullName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> cashierFullNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cashierFullName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> cashierFullNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cashierFullName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> cashierFullNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cashierFullName',
        value: '',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> cashierFullNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cashierFullName',
        value: '',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> changeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'change',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> changeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'change',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> changeEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'change',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> changeGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'change',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> changeLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'change',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> changeBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'change',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> createdByNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'createdByName',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> createdByNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'createdByName',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> createdByNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdByName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> createdByNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdByName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> createdByNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdByName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> createdByNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdByName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> createdByNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'createdByName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> createdByNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'createdByName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> createdByNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'createdByName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> createdByNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'createdByName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> createdByNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdByName',
        value: '',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> createdByNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'createdByName',
        value: '',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> customerAccBankTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'customerAccBankType',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition>
      customerAccBankTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'customerAccBankType',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> customerAccBankTypeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customerAccBankType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition>
      customerAccBankTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'customerAccBankType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> customerAccBankTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'customerAccBankType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> customerAccBankTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'customerAccBankType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> customerAccBankTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'customerAccBankType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> customerAccBankTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'customerAccBankType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> customerAccBankTypeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'customerAccBankType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> customerAccBankTypeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'customerAccBankType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> customerAccBankTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customerAccBankType',
        value: '',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition>
      customerAccBankTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'customerAccBankType',
        value: '',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> dateCreatedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'dateCreated',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> dateCreatedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'dateCreated',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> dateCreatedEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateCreated',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> dateCreatedGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dateCreated',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> dateCreatedLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dateCreated',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> dateCreatedBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dateCreated',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> dateCreatedStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'dateCreated',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> dateCreatedEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'dateCreated',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> dateCreatedContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dateCreated',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> dateCreatedMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dateCreated',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> dateCreatedIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateCreated',
        value: '',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> dateCreatedIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dateCreated',
        value: '',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> dateModifiedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'dateModified',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> dateModifiedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'dateModified',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> dateModifiedEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateModified',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> dateModifiedGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dateModified',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> dateModifiedLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dateModified',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> dateModifiedBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dateModified',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> dateModifiedStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'dateModified',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> dateModifiedEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'dateModified',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> dateModifiedContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dateModified',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> dateModifiedMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dateModified',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> dateModifiedIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateModified',
        value: '',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> dateModifiedIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dateModified',
        value: '',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> fiscalizedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fiscalized',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> fiscalizedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fiscalized',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> fiscalizedEqualTo(
      bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fiscalized',
        value: value,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> idEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> idGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> idLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> idBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> idContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> idMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> isarIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> isarIdLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> kotNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'kotNumber',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> kotNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'kotNumber',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> kotNumberEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kotNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> kotNumberGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'kotNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> kotNumberLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'kotNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> kotNumberBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'kotNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> modifiedByNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'modifiedByName',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> modifiedByNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'modifiedByName',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> modifiedByNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'modifiedByName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> modifiedByNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'modifiedByName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> modifiedByNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'modifiedByName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> modifiedByNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'modifiedByName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> modifiedByNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'modifiedByName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> modifiedByNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'modifiedByName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> modifiedByNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'modifiedByName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> modifiedByNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'modifiedByName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> modifiedByNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'modifiedByName',
        value: '',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> modifiedByNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'modifiedByName',
        value: '',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> posReferenceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'posReference',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> posReferenceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'posReference',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> posReferenceEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'posReference',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> posReferenceGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'posReference',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> posReferenceLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'posReference',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> posReferenceBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'posReference',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> posReferenceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'posReference',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> posReferenceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'posReference',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> posReferenceContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'posReference',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> posReferenceMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'posReference',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> posReferenceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'posReference',
        value: '',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> posReferenceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'posReference',
        value: '',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> receiptQrCodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'receiptQrCode',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> receiptQrCodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'receiptQrCode',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> receiptQrCodeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'receiptQrCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> receiptQrCodeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'receiptQrCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> receiptQrCodeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'receiptQrCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> receiptQrCodeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'receiptQrCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> receiptQrCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'receiptQrCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> receiptQrCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'receiptQrCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> receiptQrCodeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'receiptQrCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> receiptQrCodeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'receiptQrCode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> receiptQrCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'receiptQrCode',
        value: '',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> receiptQrCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'receiptQrCode',
        value: '',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> receiptQrDataIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'receiptQrData',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> receiptQrDataIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'receiptQrData',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> receiptQrDataEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'receiptQrData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> receiptQrDataGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'receiptQrData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> receiptQrDataLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'receiptQrData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> receiptQrDataBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'receiptQrData',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> receiptQrDataStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'receiptQrData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> receiptQrDataEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'receiptQrData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> receiptQrDataContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'receiptQrData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> receiptQrDataMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'receiptQrData',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> receiptQrDataIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'receiptQrData',
        value: '',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> receiptQrDataIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'receiptQrData',
        value: '',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> referenceNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'referenceNumber',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> referenceNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'referenceNumber',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> referenceNumberEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'referenceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> referenceNumberGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'referenceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> referenceNumberLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'referenceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> referenceNumberBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'referenceNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> referenceNumberStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'referenceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> referenceNumberEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'referenceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> referenceNumberContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'referenceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> referenceNumberMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'referenceNumber',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> referenceNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'referenceNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> referenceNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'referenceNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> saleStatusIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'saleStatus',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> saleStatusIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'saleStatus',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> saleStatusEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'saleStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> saleStatusGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'saleStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> saleStatusLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'saleStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> saleStatusBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'saleStatus',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> saleStatusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'saleStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> saleStatusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'saleStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> saleStatusContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'saleStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> saleStatusMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'saleStatus',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> saleStatusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'saleStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> saleStatusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'saleStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> shiftReferenceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'shiftReference',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> shiftReferenceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'shiftReference',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> shiftReferenceEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'shiftReference',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> shiftReferenceGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'shiftReference',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> shiftReferenceLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'shiftReference',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> shiftReferenceBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'shiftReference',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> shiftReferenceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'shiftReference',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> shiftReferenceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'shiftReference',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> shiftReferenceContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'shiftReference',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> shiftReferenceMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'shiftReference',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> shiftReferenceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'shiftReference',
        value: '',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> shiftReferenceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'shiftReference',
        value: '',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> taxInvoiceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'taxInvoice',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> taxInvoiceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'taxInvoice',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> taxInvoiceEqualTo(
      bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'taxInvoice',
        value: value,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> ticketNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'ticketName',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> ticketNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'ticketName',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> ticketNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ticketName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> ticketNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ticketName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> ticketNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ticketName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> ticketNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ticketName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> ticketNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ticketName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> ticketNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ticketName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> ticketNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ticketName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> ticketNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ticketName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> ticketNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ticketName',
        value: '',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> ticketNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ticketName',
        value: '',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> timeCompletedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'timeCompleted',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> timeCompletedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'timeCompleted',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> timeCompletedEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timeCompleted',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> timeCompletedGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timeCompleted',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> timeCompletedLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timeCompleted',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> timeCompletedBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timeCompleted',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> timeCompletedStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'timeCompleted',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> timeCompletedEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'timeCompleted',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> timeCompletedContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'timeCompleted',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> timeCompletedMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'timeCompleted',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> timeCompletedIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timeCompleted',
        value: '',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> timeCompletedIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'timeCompleted',
        value: '',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> timeIniatedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'timeIniated',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> timeIniatedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'timeIniated',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> timeIniatedEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timeIniated',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> timeIniatedGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timeIniated',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> timeIniatedLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timeIniated',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> timeIniatedBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timeIniated',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> timeIniatedStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'timeIniated',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> timeIniatedEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'timeIniated',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> timeIniatedContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'timeIniated',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> timeIniatedMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'timeIniated',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> timeIniatedIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timeIniated',
        value: '',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> timeIniatedIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'timeIniated',
        value: '',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> totalDiscountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'totalDiscount',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> totalDiscountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'totalDiscount',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> totalDiscountEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalDiscount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> totalDiscountGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalDiscount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> totalDiscountLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalDiscount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> totalDiscountBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalDiscount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> totalQuantityIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'totalQuantity',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> totalQuantityIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'totalQuantity',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> totalQuantityEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalQuantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> totalQuantityGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalQuantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> totalQuantityLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalQuantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> totalQuantityBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalQuantity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> totalTaxAmountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'totalTaxAmount',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> totalTaxAmountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'totalTaxAmount',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> totalTaxAmountEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalTaxAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> totalTaxAmountGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalTaxAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> totalTaxAmountLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalTaxAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> totalTaxAmountBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalTaxAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> versionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'version',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> versionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'version',
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> versionEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'version',
        value: value,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> versionGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'version',
        value: value,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> versionLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'version',
        value: value,
      ));
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> versionBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'version',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension SaleQueryObject on QueryBuilder<Sale, Sale, QFilterCondition> {}

extension SaleQueryLinks on QueryBuilder<Sale, Sale, QFilterCondition> {
  QueryBuilder<Sale, Sale, QAfterFilterCondition> customer(
      FilterQuery<Customer> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'customer');
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> customerIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'customer', 0, true, 0, true);
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> company(
      FilterQuery<Company> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'company');
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> companyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'company', 0, true, 0, true);
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> branch(
      FilterQuery<Branch> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'branch');
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> branchIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'branch', 0, true, 0, true);
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> items(
      FilterQuery<SaleItem> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'items');
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> itemsLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'items', length, true, length, true);
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> itemsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'items', 0, true, 0, true);
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> itemsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'items', 0, false, 999999, true);
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> itemsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'items', 0, true, length, include);
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> itemsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'items', length, include, 999999, true);
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> itemsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'items', lower, includeLower, upper, includeUpper);
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> paymentTypes(
      FilterQuery<PaymentReceived> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'paymentTypes');
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> paymentTypesLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'paymentTypes', length, true, length, true);
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> paymentTypesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'paymentTypes', 0, true, 0, true);
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> paymentTypesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'paymentTypes', 0, false, 999999, true);
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> paymentTypesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'paymentTypes', 0, true, length, include);
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> paymentTypesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'paymentTypes', length, include, 999999, true);
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> paymentTypesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'paymentTypes', lower, includeLower, upper, includeUpper);
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> currency(
      FilterQuery<Currency> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'currency');
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> currencyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'currency', 0, true, 0, true);
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> baseCurrency(
      FilterQuery<Currency> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'baseCurrency');
    });
  }

  QueryBuilder<Sale, Sale, QAfterFilterCondition> baseCurrencyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'baseCurrency', 0, true, 0, true);
    });
  }
}

extension SaleQuerySortBy on QueryBuilder<Sale, Sale, QSortBy> {
  QueryBuilder<Sale, Sale, QAfterSortBy> sortByAmountAfterDiscount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountAfterDiscount', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByAmountAfterDiscountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountAfterDiscount', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByAmountPaid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountPaid', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByAmountPaidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountPaid', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByAmountTendered() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountTendered', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByAmountTenderedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountTendered', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByAmtToAcc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amtToAcc', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByAmtToAccDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amtToAcc', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByBaseSaleAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseSaleAmount', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByBaseSaleAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseSaleAmount', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByCashierFullName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cashierFullName', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByCashierFullNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cashierFullName', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByChange() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'change', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByChangeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'change', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByCreatedByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdByName', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByCreatedByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdByName', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByCustomerAccBankType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerAccBankType', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByCustomerAccBankTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerAccBankType', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByDateCreated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateCreated', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByDateCreatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateCreated', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByDateModified() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateModified', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByDateModifiedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateModified', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByFiscalized() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fiscalized', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByFiscalizedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fiscalized', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByKotNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kotNumber', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByKotNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kotNumber', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByModifiedByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modifiedByName', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByModifiedByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modifiedByName', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByPosReference() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'posReference', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByPosReferenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'posReference', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByReceiptQrCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptQrCode', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByReceiptQrCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptQrCode', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByReceiptQrData() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptQrData', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByReceiptQrDataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptQrData', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByReferenceNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceNumber', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByReferenceNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceNumber', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortBySaleStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'saleStatus', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortBySaleStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'saleStatus', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByShiftReference() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shiftReference', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByShiftReferenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shiftReference', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByTaxInvoice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxInvoice', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByTaxInvoiceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxInvoice', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByTicketName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ticketName', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByTicketNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ticketName', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByTimeCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeCompleted', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByTimeCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeCompleted', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByTimeIniated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeIniated', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByTimeIniatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeIniated', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByTotalDiscount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalDiscount', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByTotalDiscountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalDiscount', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByTotalQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalQuantity', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByTotalQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalQuantity', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByTotalTaxAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalTaxAmount', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByTotalTaxAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalTaxAmount', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> sortByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension SaleQuerySortThenBy on QueryBuilder<Sale, Sale, QSortThenBy> {
  QueryBuilder<Sale, Sale, QAfterSortBy> thenByAmountAfterDiscount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountAfterDiscount', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByAmountAfterDiscountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountAfterDiscount', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByAmountPaid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountPaid', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByAmountPaidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountPaid', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByAmountTendered() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountTendered', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByAmountTenderedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountTendered', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByAmtToAcc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amtToAcc', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByAmtToAccDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amtToAcc', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByBaseSaleAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseSaleAmount', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByBaseSaleAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseSaleAmount', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByCashierFullName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cashierFullName', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByCashierFullNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cashierFullName', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByChange() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'change', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByChangeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'change', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByCreatedByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdByName', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByCreatedByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdByName', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByCustomerAccBankType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerAccBankType', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByCustomerAccBankTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerAccBankType', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByDateCreated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateCreated', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByDateCreatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateCreated', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByDateModified() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateModified', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByDateModifiedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateModified', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByFiscalized() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fiscalized', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByFiscalizedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fiscalized', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByKotNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kotNumber', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByKotNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kotNumber', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByModifiedByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modifiedByName', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByModifiedByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modifiedByName', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByPosReference() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'posReference', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByPosReferenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'posReference', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByReceiptQrCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptQrCode', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByReceiptQrCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptQrCode', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByReceiptQrData() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptQrData', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByReceiptQrDataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receiptQrData', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByReferenceNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceNumber', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByReferenceNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceNumber', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenBySaleStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'saleStatus', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenBySaleStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'saleStatus', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByShiftReference() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shiftReference', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByShiftReferenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shiftReference', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByTaxInvoice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxInvoice', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByTaxInvoiceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taxInvoice', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByTicketName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ticketName', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByTicketNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ticketName', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByTimeCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeCompleted', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByTimeCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeCompleted', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByTimeIniated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeIniated', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByTimeIniatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeIniated', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByTotalDiscount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalDiscount', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByTotalDiscountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalDiscount', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByTotalQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalQuantity', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByTotalQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalQuantity', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByTotalTaxAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalTaxAmount', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByTotalTaxAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalTaxAmount', Sort.desc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<Sale, Sale, QAfterSortBy> thenByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension SaleQueryWhereDistinct on QueryBuilder<Sale, Sale, QDistinct> {
  QueryBuilder<Sale, Sale, QDistinct> distinctByAmountAfterDiscount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amountAfterDiscount');
    });
  }

  QueryBuilder<Sale, Sale, QDistinct> distinctByAmountPaid() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amountPaid');
    });
  }

  QueryBuilder<Sale, Sale, QDistinct> distinctByAmountTendered() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amountTendered');
    });
  }

  QueryBuilder<Sale, Sale, QDistinct> distinctByAmtToAcc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amtToAcc', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Sale, Sale, QDistinct> distinctByBaseSaleAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'baseSaleAmount');
    });
  }

  QueryBuilder<Sale, Sale, QDistinct> distinctByCashierFullName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cashierFullName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Sale, Sale, QDistinct> distinctByChange() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'change');
    });
  }

  QueryBuilder<Sale, Sale, QDistinct> distinctByCreatedByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdByName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Sale, Sale, QDistinct> distinctByCustomerAccBankType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'customerAccBankType',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Sale, Sale, QDistinct> distinctByDateCreated(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateCreated', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Sale, Sale, QDistinct> distinctByDateModified(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateModified', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Sale, Sale, QDistinct> distinctByFiscalized() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fiscalized');
    });
  }

  QueryBuilder<Sale, Sale, QDistinct> distinctById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Sale, Sale, QDistinct> distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<Sale, Sale, QDistinct> distinctByKotNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'kotNumber');
    });
  }

  QueryBuilder<Sale, Sale, QDistinct> distinctByModifiedByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'modifiedByName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Sale, Sale, QDistinct> distinctByPosReference(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'posReference', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Sale, Sale, QDistinct> distinctByReceiptQrCode(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'receiptQrCode',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Sale, Sale, QDistinct> distinctByReceiptQrData(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'receiptQrData',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Sale, Sale, QDistinct> distinctByReferenceNumber(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'referenceNumber',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Sale, Sale, QDistinct> distinctBySaleStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'saleStatus', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Sale, Sale, QDistinct> distinctByShiftReference(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'shiftReference',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Sale, Sale, QDistinct> distinctByTaxInvoice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'taxInvoice');
    });
  }

  QueryBuilder<Sale, Sale, QDistinct> distinctByTicketName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ticketName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Sale, Sale, QDistinct> distinctByTimeCompleted(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timeCompleted',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Sale, Sale, QDistinct> distinctByTimeIniated(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timeIniated', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Sale, Sale, QDistinct> distinctByTotalDiscount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalDiscount');
    });
  }

  QueryBuilder<Sale, Sale, QDistinct> distinctByTotalQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalQuantity');
    });
  }

  QueryBuilder<Sale, Sale, QDistinct> distinctByTotalTaxAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalTaxAmount');
    });
  }

  QueryBuilder<Sale, Sale, QDistinct> distinctByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'version');
    });
  }
}

extension SaleQueryProperty on QueryBuilder<Sale, Sale, QQueryProperty> {
  QueryBuilder<Sale, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<Sale, double?, QQueryOperations> amountAfterDiscountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amountAfterDiscount');
    });
  }

  QueryBuilder<Sale, double?, QQueryOperations> amountPaidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amountPaid');
    });
  }

  QueryBuilder<Sale, double?, QQueryOperations> amountTenderedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amountTendered');
    });
  }

  QueryBuilder<Sale, String?, QQueryOperations> amtToAccProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amtToAcc');
    });
  }

  QueryBuilder<Sale, double?, QQueryOperations> baseSaleAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'baseSaleAmount');
    });
  }

  QueryBuilder<Sale, String?, QQueryOperations> cashierFullNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cashierFullName');
    });
  }

  QueryBuilder<Sale, double?, QQueryOperations> changeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'change');
    });
  }

  QueryBuilder<Sale, String?, QQueryOperations> createdByNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdByName');
    });
  }

  QueryBuilder<Sale, String?, QQueryOperations> customerAccBankTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customerAccBankType');
    });
  }

  QueryBuilder<Sale, String?, QQueryOperations> dateCreatedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateCreated');
    });
  }

  QueryBuilder<Sale, String?, QQueryOperations> dateModifiedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateModified');
    });
  }

  QueryBuilder<Sale, bool?, QQueryOperations> fiscalizedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fiscalized');
    });
  }

  QueryBuilder<Sale, String?, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Sale, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<Sale, int?, QQueryOperations> kotNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'kotNumber');
    });
  }

  QueryBuilder<Sale, String?, QQueryOperations> modifiedByNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'modifiedByName');
    });
  }

  QueryBuilder<Sale, String?, QQueryOperations> posReferenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'posReference');
    });
  }

  QueryBuilder<Sale, String?, QQueryOperations> receiptQrCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'receiptQrCode');
    });
  }

  QueryBuilder<Sale, String?, QQueryOperations> receiptQrDataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'receiptQrData');
    });
  }

  QueryBuilder<Sale, String?, QQueryOperations> referenceNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'referenceNumber');
    });
  }

  QueryBuilder<Sale, String?, QQueryOperations> saleStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'saleStatus');
    });
  }

  QueryBuilder<Sale, String?, QQueryOperations> shiftReferenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'shiftReference');
    });
  }

  QueryBuilder<Sale, bool?, QQueryOperations> taxInvoiceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'taxInvoice');
    });
  }

  QueryBuilder<Sale, String?, QQueryOperations> ticketNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ticketName');
    });
  }

  QueryBuilder<Sale, String?, QQueryOperations> timeCompletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timeCompleted');
    });
  }

  QueryBuilder<Sale, String?, QQueryOperations> timeIniatedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timeIniated');
    });
  }

  QueryBuilder<Sale, double?, QQueryOperations> totalDiscountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalDiscount');
    });
  }

  QueryBuilder<Sale, double?, QQueryOperations> totalQuantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalQuantity');
    });
  }

  QueryBuilder<Sale, double?, QQueryOperations> totalTaxAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalTaxAmount');
    });
  }

  QueryBuilder<Sale, int?, QQueryOperations> versionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'version');
    });
  }
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Sale _$SaleFromJson(Map<String, dynamic> json) => Sale(
      id: json['id'] as String?,
      dateCreated: json['dateCreated'] as String?,
      dateModified: json['dateModified'] as String?,
      createdByName: json['createdByName'] as String?,
      modifiedByName: json['modifiedByName'] as String?,
      version: (json['version'] as num?)?.toInt(),
      cashierFullName: json['cashierFullName'] as String?,
      timeIniated: json['timeIniated'] as String?,
      timeCompleted: json['timeCompleted'] as String?,
      saleStatus: json['saleStatus'] as String?,
      amountAfterDiscount: (json['amountAfterDiscount'] as num?)?.toDouble(),
      baseSaleAmount: (json['baseSaleAmount'] as num?)?.toDouble(),
      totalTaxAmount: (json['totalTaxAmount'] as num?)?.toDouble(),
      isSynced: json['isSynced'] as bool? ?? false,
      fiscalized: json['fiscalized'] as bool?,
      taxInvoice: json['taxInvoice'] as bool?,
      totalQuantity: (json['totalQuantity'] as num?)?.toDouble(),
      posReference: json['posReference'] as String?,
      kotNumber: (json['kotNumber'] as num?)?.toInt(),
      referenceNumber: json['referenceNumber'] as String?,
      shiftReference: json['shiftReference'] as String?,
      ticketName: json['ticketName'] as String?,
      ticketComment: json['ticketComment'] as String?,
      amtToAcc: json['amtToAcc'] as String?,
      customerAccBankType: json['customerAccBankType'] as String?,
      amountPaid: (json['amountPaid'] as num?)?.toDouble(),
      change: (json['change'] as num?)?.toDouble(),
      amountTendered: (json['amountTendered'] as num?)?.toDouble(),
      receiptQrCode: json['receiptQrCode'] as String?,
      receiptQrData: json['receiptQrData'] as String?,
      heldItems: (json['heldItems'] as List<dynamic>?)
              ?.map((e) => SaleItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      heldCurrency: json['heldCurrency'] == null
          ? null
          : Currency.fromJson(json['heldCurrency'] as Map<String, dynamic>),
      heldBranch: json['heldBranch'] == null
          ? null
          : Branch.fromJson(json['heldBranch'] as Map<String, dynamic>),
      heldCustomer: json['heldCustomer'] == null
          ? null
          : Customer.fromJson(json['heldCustomer'] as Map<String, dynamic>),
      totalDiscount: (json['totalDiscount'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$SaleToJson(Sale instance) => <String, dynamic>{
      'id': instance.id,
      'dateCreated': instance.dateCreated,
      'dateModified': instance.dateModified,
      'createdByName': instance.createdByName,
      'modifiedByName': instance.modifiedByName,
      'version': instance.version,
      'cashierFullName': instance.cashierFullName,
      'heldItems': instance.heldItems.map((e) => e.toJson()).toList(),
      'heldCurrency': instance.heldCurrency?.toJson(),
      'heldCustomer': instance.heldCustomer?.toJson(),
      'timeIniated': instance.timeIniated,
      'timeCompleted': instance.timeCompleted,
      'saleStatus': instance.saleStatus,
      'amountAfterDiscount': instance.amountAfterDiscount,
      'baseSaleAmount': instance.baseSaleAmount,
      'totalTaxAmount': instance.totalTaxAmount,
      'isSynced': instance.isSynced,
      'fiscalized': instance.fiscalized,
      'taxInvoice': instance.taxInvoice,
      'totalQuantity': instance.totalQuantity,
      'totalDiscount': instance.totalDiscount,
      'posReference': instance.posReference,
      'kotNumber': instance.kotNumber,
      'referenceNumber': instance.referenceNumber,
      'shiftReference': instance.shiftReference,
      'ticketName': instance.ticketName,
      'ticketComment': instance.ticketComment,
      'amtToAcc': instance.amtToAcc,
      'customerAccBankType': instance.customerAccBankType,
      'amountPaid': instance.amountPaid,
      'change': instance.change,
      'amountTendered': instance.amountTendered,
      'receiptQrCode': instance.receiptQrCode,
      'receiptQrData': instance.receiptQrData,
    };
