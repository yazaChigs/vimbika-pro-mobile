// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_received.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPaymentReceivedCollection on Isar {
  IsarCollection<PaymentReceived> get paymentReceiveds => this.collection();
}

const PaymentReceivedSchema = CollectionSchema(
  name: r'PaymentReceived',
  id: -8881471945458554851,
  properties: {
    r'accountType': PropertySchema(
      id: 0,
      name: r'accountType',
      type: IsarType.string,
    ),
    r'amount': PropertySchema(
      id: 1,
      name: r'amount',
      type: IsarType.double,
    ),
    r'amountAddedToAccount': PropertySchema(
      id: 2,
      name: r'amountAddedToAccount',
      type: IsarType.double,
    ),
    r'amountPaid': PropertySchema(
      id: 3,
      name: r'amountPaid',
      type: IsarType.double,
    ),
    r'amountTendered': PropertySchema(
      id: 4,
      name: r'amountTendered',
      type: IsarType.double,
    ),
    r'dateTime': PropertySchema(
      id: 5,
      name: r'dateTime',
      type: IsarType.string,
    ),
    r'id': PropertySchema(
      id: 6,
      name: r'id',
      type: IsarType.string,
    ),
    r'isMobile': PropertySchema(
      id: 7,
      name: r'isMobile',
      type: IsarType.bool,
    ),
    r'isSynced': PropertySchema(
      id: 8,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'notes': PropertySchema(
      id: 9,
      name: r'notes',
      type: IsarType.string,
    ),
    r'paymentDate': PropertySchema(
      id: 10,
      name: r'paymentDate',
      type: IsarType.string,
    ),
    r'paymentDescription': PropertySchema(
      id: 11,
      name: r'paymentDescription',
      type: IsarType.string,
    ),
    r'posReference': PropertySchema(
      id: 12,
      name: r'posReference',
      type: IsarType.string,
    ),
    r'reference': PropertySchema(
      id: 13,
      name: r'reference',
      type: IsarType.string,
    )
  },
  estimateSize: _paymentReceivedEstimateSize,
  serialize: _paymentReceivedSerialize,
  deserialize: _paymentReceivedDeserialize,
  deserializeProp: _paymentReceivedDeserializeProp,
  idName: r'isarId',
  indexes: {},
  links: {
    r'paymentType': LinkSchema(
      id: 9162255624268097081,
      name: r'paymentType',
      target: r'PaymentType',
      single: true,
    ),
    r'payer': LinkSchema(
      id: 7904850023975305893,
      name: r'payer',
      target: r'Customer',
      single: true,
    ),
    r'currency': LinkSchema(
      id: -6064490283869328192,
      name: r'currency',
      target: r'Currency',
      single: true,
    ),
    r'branch': LinkSchema(
      id: -6024498300176682473,
      name: r'branch',
      target: r'Branch',
      single: true,
    ),
    r'bank': LinkSchema(
      id: -3498957021458795637,
      name: r'bank',
      target: r'Bank',
      single: true,
    )
  },
  embeddedSchemas: {},
  getId: _paymentReceivedGetId,
  getLinks: _paymentReceivedGetLinks,
  attach: _paymentReceivedAttach,
  version: '3.1.0+1',
);

int _paymentReceivedEstimateSize(
  PaymentReceived object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.accountType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.dateTime;
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
    final value = object.notes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.paymentDate;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.paymentDescription;
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
    final value = object.reference;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _paymentReceivedSerialize(
  PaymentReceived object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.accountType);
  writer.writeDouble(offsets[1], object.amount);
  writer.writeDouble(offsets[2], object.amountAddedToAccount);
  writer.writeDouble(offsets[3], object.amountPaid);
  writer.writeDouble(offsets[4], object.amountTendered);
  writer.writeString(offsets[5], object.dateTime);
  writer.writeString(offsets[6], object.id);
  writer.writeBool(offsets[7], object.isMobile);
  writer.writeBool(offsets[8], object.isSynced);
  writer.writeString(offsets[9], object.notes);
  writer.writeString(offsets[10], object.paymentDate);
  writer.writeString(offsets[11], object.paymentDescription);
  writer.writeString(offsets[12], object.posReference);
  writer.writeString(offsets[13], object.reference);
}

PaymentReceived _paymentReceivedDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PaymentReceived(
    accountType: reader.readStringOrNull(offsets[0]),
    amount: reader.readDoubleOrNull(offsets[1]) ?? 0.0,
    amountAddedToAccount: reader.readDoubleOrNull(offsets[2]) ?? 0.0,
    amountPaid: reader.readDoubleOrNull(offsets[3]),
    amountTendered: reader.readDoubleOrNull(offsets[4]),
    dateTime: reader.readStringOrNull(offsets[5]),
    id: reader.readStringOrNull(offsets[6]),
    isMobile: reader.readBoolOrNull(offsets[7]) ?? false,
    isSynced: reader.readBoolOrNull(offsets[8]) ?? true,
    notes: reader.readStringOrNull(offsets[9]),
    paymentDate: reader.readStringOrNull(offsets[10]),
    paymentDescription: reader.readStringOrNull(offsets[11]),
    posReference: reader.readStringOrNull(offsets[12]),
    reference: reader.readStringOrNull(offsets[13]),
  );
  object.isarId = id;
  return object;
}

P _paymentReceivedDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 2:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 3:
      return (reader.readDoubleOrNull(offset)) as P;
    case 4:
      return (reader.readDoubleOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 8:
      return (reader.readBoolOrNull(offset) ?? true) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _paymentReceivedGetId(PaymentReceived object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _paymentReceivedGetLinks(PaymentReceived object) {
  return [
    object.paymentType,
    object.payer,
    object.currency,
    object.branch,
    object.bank
  ];
}

void _paymentReceivedAttach(
    IsarCollection<dynamic> col, Id id, PaymentReceived object) {
  object.isarId = id;
  object.paymentType
      .attach(col, col.isar.collection<PaymentType>(), r'paymentType', id);
  object.payer.attach(col, col.isar.collection<Customer>(), r'payer', id);
  object.currency.attach(col, col.isar.collection<Currency>(), r'currency', id);
  object.branch.attach(col, col.isar.collection<Branch>(), r'branch', id);
  object.bank.attach(col, col.isar.collection<Bank>(), r'bank', id);
}

extension PaymentReceivedQueryWhereSort
    on QueryBuilder<PaymentReceived, PaymentReceived, QWhere> {
  QueryBuilder<PaymentReceived, PaymentReceived, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PaymentReceivedQueryWhere
    on QueryBuilder<PaymentReceived, PaymentReceived, QWhereClause> {
  QueryBuilder<PaymentReceived, PaymentReceived, QAfterWhereClause>
      isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterWhereClause>
      isarIdNotEqualTo(Id isarId) {
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

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterWhereClause>
      isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterWhereClause>
      isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterWhereClause>
      isarIdBetween(
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

extension PaymentReceivedQueryFilter
    on QueryBuilder<PaymentReceived, PaymentReceived, QFilterCondition> {
  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      accountTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'accountType',
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      accountTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'accountType',
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      accountTypeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accountType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      accountTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'accountType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      accountTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'accountType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      accountTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'accountType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      accountTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'accountType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      accountTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'accountType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      accountTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'accountType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      accountTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'accountType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      accountTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accountType',
        value: '',
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      accountTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'accountType',
        value: '',
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      amountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      amountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      amountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      amountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'amount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      amountAddedToAccountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amountAddedToAccount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      amountAddedToAccountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'amountAddedToAccount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      amountAddedToAccountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'amountAddedToAccount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      amountAddedToAccountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'amountAddedToAccount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      amountPaidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'amountPaid',
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      amountPaidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'amountPaid',
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      amountPaidEqualTo(
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

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      amountPaidGreaterThan(
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

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      amountPaidLessThan(
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

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      amountPaidBetween(
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

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      amountTenderedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'amountTendered',
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      amountTenderedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'amountTendered',
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      amountTenderedEqualTo(
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

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      amountTenderedGreaterThan(
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

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      amountTenderedLessThan(
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

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      amountTenderedBetween(
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

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      dateTimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'dateTime',
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      dateTimeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'dateTime',
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      dateTimeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      dateTimeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dateTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      dateTimeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dateTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      dateTimeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dateTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      dateTimeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'dateTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      dateTimeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'dateTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      dateTimeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dateTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      dateTimeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dateTime',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      dateTimeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateTime',
        value: '',
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      dateTimeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dateTime',
        value: '',
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      idEqualTo(
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

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      idStartsWith(
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

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      idEndsWith(
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

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      idContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      idMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      isMobileEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isMobile',
        value: value,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      isarIdGreaterThan(
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

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      isarIdLessThan(
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

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      isarIdBetween(
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

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      notesEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      notesGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      notesLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      notesBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'notes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      notesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      notesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      notesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      notesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      paymentDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'paymentDate',
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      paymentDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'paymentDate',
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      paymentDateEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paymentDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      paymentDateGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'paymentDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      paymentDateLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'paymentDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      paymentDateBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'paymentDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      paymentDateStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'paymentDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      paymentDateEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'paymentDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      paymentDateContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'paymentDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      paymentDateMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'paymentDate',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      paymentDateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paymentDate',
        value: '',
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      paymentDateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'paymentDate',
        value: '',
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      paymentDescriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'paymentDescription',
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      paymentDescriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'paymentDescription',
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      paymentDescriptionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paymentDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      paymentDescriptionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'paymentDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      paymentDescriptionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'paymentDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      paymentDescriptionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'paymentDescription',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      paymentDescriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'paymentDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      paymentDescriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'paymentDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      paymentDescriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'paymentDescription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      paymentDescriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'paymentDescription',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      paymentDescriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paymentDescription',
        value: '',
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      paymentDescriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'paymentDescription',
        value: '',
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      posReferenceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'posReference',
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      posReferenceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'posReference',
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      posReferenceEqualTo(
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

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      posReferenceGreaterThan(
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

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      posReferenceLessThan(
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

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      posReferenceBetween(
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

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      posReferenceStartsWith(
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

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      posReferenceEndsWith(
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

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      posReferenceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'posReference',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      posReferenceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'posReference',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      posReferenceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'posReference',
        value: '',
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      posReferenceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'posReference',
        value: '',
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      referenceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'reference',
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      referenceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'reference',
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      referenceEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reference',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      referenceGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'reference',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      referenceLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'reference',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      referenceBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'reference',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      referenceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'reference',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      referenceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'reference',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      referenceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'reference',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      referenceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'reference',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      referenceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reference',
        value: '',
      ));
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      referenceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'reference',
        value: '',
      ));
    });
  }
}

extension PaymentReceivedQueryObject
    on QueryBuilder<PaymentReceived, PaymentReceived, QFilterCondition> {}

extension PaymentReceivedQueryLinks
    on QueryBuilder<PaymentReceived, PaymentReceived, QFilterCondition> {
  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      paymentType(FilterQuery<PaymentType> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'paymentType');
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      paymentTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'paymentType', 0, true, 0, true);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition> payer(
      FilterQuery<Customer> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'payer');
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      payerIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'payer', 0, true, 0, true);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      currency(FilterQuery<Currency> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'currency');
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      currencyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'currency', 0, true, 0, true);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition> branch(
      FilterQuery<Branch> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'branch');
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      branchIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'branch', 0, true, 0, true);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition> bank(
      FilterQuery<Bank> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'bank');
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterFilterCondition>
      bankIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'bank', 0, true, 0, true);
    });
  }
}

extension PaymentReceivedQuerySortBy
    on QueryBuilder<PaymentReceived, PaymentReceived, QSortBy> {
  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      sortByAccountType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountType', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      sortByAccountTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountType', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy> sortByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      sortByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      sortByAmountAddedToAccount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountAddedToAccount', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      sortByAmountAddedToAccountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountAddedToAccount', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      sortByAmountPaid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountPaid', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      sortByAmountPaidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountPaid', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      sortByAmountTendered() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountTendered', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      sortByAmountTenderedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountTendered', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      sortByDateTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateTime', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      sortByDateTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateTime', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      sortByIsMobile() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMobile', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      sortByIsMobileDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMobile', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy> sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      sortByPaymentDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentDate', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      sortByPaymentDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentDate', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      sortByPaymentDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentDescription', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      sortByPaymentDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentDescription', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      sortByPosReference() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'posReference', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      sortByPosReferenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'posReference', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      sortByReference() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reference', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      sortByReferenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reference', Sort.desc);
    });
  }
}

extension PaymentReceivedQuerySortThenBy
    on QueryBuilder<PaymentReceived, PaymentReceived, QSortThenBy> {
  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      thenByAccountType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountType', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      thenByAccountTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountType', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy> thenByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      thenByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      thenByAmountAddedToAccount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountAddedToAccount', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      thenByAmountAddedToAccountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountAddedToAccount', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      thenByAmountPaid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountPaid', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      thenByAmountPaidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountPaid', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      thenByAmountTendered() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountTendered', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      thenByAmountTenderedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountTendered', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      thenByDateTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateTime', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      thenByDateTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateTime', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      thenByIsMobile() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMobile', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      thenByIsMobileDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMobile', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy> thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      thenByPaymentDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentDate', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      thenByPaymentDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentDate', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      thenByPaymentDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentDescription', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      thenByPaymentDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentDescription', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      thenByPosReference() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'posReference', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      thenByPosReferenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'posReference', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      thenByReference() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reference', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QAfterSortBy>
      thenByReferenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reference', Sort.desc);
    });
  }
}

extension PaymentReceivedQueryWhereDistinct
    on QueryBuilder<PaymentReceived, PaymentReceived, QDistinct> {
  QueryBuilder<PaymentReceived, PaymentReceived, QDistinct>
      distinctByAccountType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'accountType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QDistinct> distinctByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amount');
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QDistinct>
      distinctByAmountAddedToAccount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amountAddedToAccount');
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QDistinct>
      distinctByAmountPaid() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amountPaid');
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QDistinct>
      distinctByAmountTendered() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amountTendered');
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QDistinct> distinctByDateTime(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateTime', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QDistinct> distinctById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QDistinct>
      distinctByIsMobile() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isMobile');
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QDistinct>
      distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QDistinct> distinctByNotes(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QDistinct>
      distinctByPaymentDate({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'paymentDate', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QDistinct>
      distinctByPaymentDescription({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'paymentDescription',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QDistinct>
      distinctByPosReference({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'posReference', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PaymentReceived, PaymentReceived, QDistinct> distinctByReference(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reference', caseSensitive: caseSensitive);
    });
  }
}

extension PaymentReceivedQueryProperty
    on QueryBuilder<PaymentReceived, PaymentReceived, QQueryProperty> {
  QueryBuilder<PaymentReceived, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<PaymentReceived, String?, QQueryOperations>
      accountTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'accountType');
    });
  }

  QueryBuilder<PaymentReceived, double, QQueryOperations> amountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amount');
    });
  }

  QueryBuilder<PaymentReceived, double, QQueryOperations>
      amountAddedToAccountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amountAddedToAccount');
    });
  }

  QueryBuilder<PaymentReceived, double?, QQueryOperations>
      amountPaidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amountPaid');
    });
  }

  QueryBuilder<PaymentReceived, double?, QQueryOperations>
      amountTenderedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amountTendered');
    });
  }

  QueryBuilder<PaymentReceived, String?, QQueryOperations> dateTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateTime');
    });
  }

  QueryBuilder<PaymentReceived, String?, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PaymentReceived, bool, QQueryOperations> isMobileProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isMobile');
    });
  }

  QueryBuilder<PaymentReceived, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<PaymentReceived, String?, QQueryOperations> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<PaymentReceived, String?, QQueryOperations>
      paymentDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paymentDate');
    });
  }

  QueryBuilder<PaymentReceived, String?, QQueryOperations>
      paymentDescriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paymentDescription');
    });
  }

  QueryBuilder<PaymentReceived, String?, QQueryOperations>
      posReferenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'posReference');
    });
  }

  QueryBuilder<PaymentReceived, String?, QQueryOperations> referenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reference');
    });
  }
}
