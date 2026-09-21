// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_currency_amount.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCustomerCurrencyAmountCollection on Isar {
  IsarCollection<CustomerCurrencyAmount> get customerCurrencyAmounts =>
      this.collection();
}

const CustomerCurrencyAmountSchema = CollectionSchema(
  name: r'CustomerCurrencyAmount',
  id: -3718808216699435579,
  properties: {
    r'balance': PropertySchema(
      id: 0,
      name: r'balance',
      type: IsarType.double,
    )
  },
  estimateSize: _customerCurrencyAmountEstimateSize,
  serialize: _customerCurrencyAmountSerialize,
  deserialize: _customerCurrencyAmountDeserialize,
  deserializeProp: _customerCurrencyAmountDeserializeProp,
  idName: r'isarId',
  indexes: {},
  links: {
    r'currency': LinkSchema(
      id: -5781693519140596014,
      name: r'currency',
      target: r'Currency',
      single: true,
    )
  },
  embeddedSchemas: {},
  getId: _customerCurrencyAmountGetId,
  getLinks: _customerCurrencyAmountGetLinks,
  attach: _customerCurrencyAmountAttach,
  version: '3.1.0+1',
);

int _customerCurrencyAmountEstimateSize(
  CustomerCurrencyAmount object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _customerCurrencyAmountSerialize(
  CustomerCurrencyAmount object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.balance);
}

CustomerCurrencyAmount _customerCurrencyAmountDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CustomerCurrencyAmount(
    balance: reader.readDoubleOrNull(offsets[0]) ?? 0.0,
  );
  object.isarId = id;
  return object;
}

P _customerCurrencyAmountDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _customerCurrencyAmountGetId(CustomerCurrencyAmount object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _customerCurrencyAmountGetLinks(
    CustomerCurrencyAmount object) {
  return [object.currency];
}

void _customerCurrencyAmountAttach(
    IsarCollection<dynamic> col, Id id, CustomerCurrencyAmount object) {
  object.isarId = id;
  object.currency.attach(col, col.isar.collection<Currency>(), r'currency', id);
}

extension CustomerCurrencyAmountQueryWhereSort
    on QueryBuilder<CustomerCurrencyAmount, CustomerCurrencyAmount, QWhere> {
  QueryBuilder<CustomerCurrencyAmount, CustomerCurrencyAmount, QAfterWhere>
      anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CustomerCurrencyAmountQueryWhere on QueryBuilder<
    CustomerCurrencyAmount, CustomerCurrencyAmount, QWhereClause> {
  QueryBuilder<CustomerCurrencyAmount, CustomerCurrencyAmount,
      QAfterWhereClause> isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<CustomerCurrencyAmount, CustomerCurrencyAmount,
      QAfterWhereClause> isarIdNotEqualTo(Id isarId) {
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

  QueryBuilder<CustomerCurrencyAmount, CustomerCurrencyAmount,
      QAfterWhereClause> isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<CustomerCurrencyAmount, CustomerCurrencyAmount,
      QAfterWhereClause> isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<CustomerCurrencyAmount, CustomerCurrencyAmount,
      QAfterWhereClause> isarIdBetween(
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

extension CustomerCurrencyAmountQueryFilter on QueryBuilder<
    CustomerCurrencyAmount, CustomerCurrencyAmount, QFilterCondition> {
  QueryBuilder<CustomerCurrencyAmount, CustomerCurrencyAmount,
      QAfterFilterCondition> balanceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'balance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CustomerCurrencyAmount, CustomerCurrencyAmount,
      QAfterFilterCondition> balanceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'balance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CustomerCurrencyAmount, CustomerCurrencyAmount,
      QAfterFilterCondition> balanceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'balance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CustomerCurrencyAmount, CustomerCurrencyAmount,
      QAfterFilterCondition> balanceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'balance',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CustomerCurrencyAmount, CustomerCurrencyAmount,
      QAfterFilterCondition> isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomerCurrencyAmount, CustomerCurrencyAmount,
      QAfterFilterCondition> isarIdGreaterThan(
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

  QueryBuilder<CustomerCurrencyAmount, CustomerCurrencyAmount,
      QAfterFilterCondition> isarIdLessThan(
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

  QueryBuilder<CustomerCurrencyAmount, CustomerCurrencyAmount,
      QAfterFilterCondition> isarIdBetween(
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
}

extension CustomerCurrencyAmountQueryObject on QueryBuilder<
    CustomerCurrencyAmount, CustomerCurrencyAmount, QFilterCondition> {}

extension CustomerCurrencyAmountQueryLinks on QueryBuilder<
    CustomerCurrencyAmount, CustomerCurrencyAmount, QFilterCondition> {
  QueryBuilder<CustomerCurrencyAmount, CustomerCurrencyAmount,
      QAfterFilterCondition> currency(FilterQuery<Currency> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'currency');
    });
  }

  QueryBuilder<CustomerCurrencyAmount, CustomerCurrencyAmount,
      QAfterFilterCondition> currencyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'currency', 0, true, 0, true);
    });
  }
}

extension CustomerCurrencyAmountQuerySortBy
    on QueryBuilder<CustomerCurrencyAmount, CustomerCurrencyAmount, QSortBy> {
  QueryBuilder<CustomerCurrencyAmount, CustomerCurrencyAmount, QAfterSortBy>
      sortByBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balance', Sort.asc);
    });
  }

  QueryBuilder<CustomerCurrencyAmount, CustomerCurrencyAmount, QAfterSortBy>
      sortByBalanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balance', Sort.desc);
    });
  }
}

extension CustomerCurrencyAmountQuerySortThenBy on QueryBuilder<
    CustomerCurrencyAmount, CustomerCurrencyAmount, QSortThenBy> {
  QueryBuilder<CustomerCurrencyAmount, CustomerCurrencyAmount, QAfterSortBy>
      thenByBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balance', Sort.asc);
    });
  }

  QueryBuilder<CustomerCurrencyAmount, CustomerCurrencyAmount, QAfterSortBy>
      thenByBalanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balance', Sort.desc);
    });
  }

  QueryBuilder<CustomerCurrencyAmount, CustomerCurrencyAmount, QAfterSortBy>
      thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<CustomerCurrencyAmount, CustomerCurrencyAmount, QAfterSortBy>
      thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }
}

extension CustomerCurrencyAmountQueryWhereDistinct
    on QueryBuilder<CustomerCurrencyAmount, CustomerCurrencyAmount, QDistinct> {
  QueryBuilder<CustomerCurrencyAmount, CustomerCurrencyAmount, QDistinct>
      distinctByBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'balance');
    });
  }
}

extension CustomerCurrencyAmountQueryProperty on QueryBuilder<
    CustomerCurrencyAmount, CustomerCurrencyAmount, QQueryProperty> {
  QueryBuilder<CustomerCurrencyAmount, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<CustomerCurrencyAmount, double, QQueryOperations>
      balanceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'balance');
    });
  }
}
