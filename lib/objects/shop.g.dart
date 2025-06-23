// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetEinkaufsladenCollection on Isar {
  IsarCollection<Einkaufsladen> get einkaufsladens => this.collection();
}

const EinkaufsladenSchema = CollectionSchema(
  name: r'Einkaufsladen',
  id: 2745446697380321082,
  properties: {
    r'excludedItems': PropertySchema(
      id: 0,
      name: r'excludedItems',
      type: IsarType.string,
    ),
    r'imagePath': PropertySchema(
      id: 1,
      name: r'imagePath',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 2,
      name: r'name',
      type: IsarType.string,
    )
  },
  estimateSize: _einkaufsladenEstimateSize,
  serialize: _einkaufsladenSerialize,
  deserialize: _einkaufsladenDeserialize,
  deserializeProp: _einkaufsladenDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _einkaufsladenGetId,
  getLinks: _einkaufsladenGetLinks,
  attach: _einkaufsladenAttach,
  version: '3.1.0+1',
);

int _einkaufsladenEstimateSize(
  Einkaufsladen object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.excludedItems;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.imagePath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  return bytesCount;
}

void _einkaufsladenSerialize(
  Einkaufsladen object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.excludedItems);
  writer.writeString(offsets[1], object.imagePath);
  writer.writeString(offsets[2], object.name);
}

Einkaufsladen _einkaufsladenDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Einkaufsladen(
    excludedItems: reader.readStringOrNull(offsets[0]),
    imagePath: reader.readStringOrNull(offsets[1]),
    name: reader.readString(offsets[2]),
  );
  object.id = id;
  return object;
}

P _einkaufsladenDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _einkaufsladenGetId(Einkaufsladen object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _einkaufsladenGetLinks(Einkaufsladen object) {
  return [];
}

void _einkaufsladenAttach(
    IsarCollection<dynamic> col, Id id, Einkaufsladen object) {
  object.id = id;
}

extension EinkaufsladenQueryWhereSort
    on QueryBuilder<Einkaufsladen, Einkaufsladen, QWhere> {
  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension EinkaufsladenQueryWhere
    on QueryBuilder<Einkaufsladen, Einkaufsladen, QWhereClause> {
  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension EinkaufsladenQueryFilter
    on QueryBuilder<Einkaufsladen, Einkaufsladen, QFilterCondition> {
  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterFilterCondition>
      excludedItemsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'excludedItems',
      ));
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterFilterCondition>
      excludedItemsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'excludedItems',
      ));
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterFilterCondition>
      excludedItemsEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'excludedItems',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterFilterCondition>
      excludedItemsGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'excludedItems',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterFilterCondition>
      excludedItemsLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'excludedItems',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterFilterCondition>
      excludedItemsBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'excludedItems',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterFilterCondition>
      excludedItemsStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'excludedItems',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterFilterCondition>
      excludedItemsEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'excludedItems',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterFilterCondition>
      excludedItemsContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'excludedItems',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterFilterCondition>
      excludedItemsMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'excludedItems',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterFilterCondition>
      excludedItemsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'excludedItems',
        value: '',
      ));
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterFilterCondition>
      excludedItemsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'excludedItems',
        value: '',
      ));
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterFilterCondition>
      imagePathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'imagePath',
      ));
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterFilterCondition>
      imagePathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'imagePath',
      ));
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterFilterCondition>
      imagePathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterFilterCondition>
      imagePathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterFilterCondition>
      imagePathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterFilterCondition>
      imagePathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'imagePath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterFilterCondition>
      imagePathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterFilterCondition>
      imagePathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterFilterCondition>
      imagePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterFilterCondition>
      imagePathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'imagePath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterFilterCondition>
      imagePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imagePath',
        value: '',
      ));
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterFilterCondition>
      imagePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'imagePath',
        value: '',
      ));
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterFilterCondition>
      nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterFilterCondition>
      nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterFilterCondition>
      nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }
}

extension EinkaufsladenQueryObject
    on QueryBuilder<Einkaufsladen, Einkaufsladen, QFilterCondition> {}

extension EinkaufsladenQueryLinks
    on QueryBuilder<Einkaufsladen, Einkaufsladen, QFilterCondition> {}

extension EinkaufsladenQuerySortBy
    on QueryBuilder<Einkaufsladen, Einkaufsladen, QSortBy> {
  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterSortBy>
      sortByExcludedItems() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'excludedItems', Sort.asc);
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterSortBy>
      sortByExcludedItemsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'excludedItems', Sort.desc);
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterSortBy> sortByImagePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.asc);
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterSortBy>
      sortByImagePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.desc);
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }
}

extension EinkaufsladenQuerySortThenBy
    on QueryBuilder<Einkaufsladen, Einkaufsladen, QSortThenBy> {
  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterSortBy>
      thenByExcludedItems() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'excludedItems', Sort.asc);
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterSortBy>
      thenByExcludedItemsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'excludedItems', Sort.desc);
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterSortBy> thenByImagePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.asc);
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterSortBy>
      thenByImagePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.desc);
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }
}

extension EinkaufsladenQueryWhereDistinct
    on QueryBuilder<Einkaufsladen, Einkaufsladen, QDistinct> {
  QueryBuilder<Einkaufsladen, Einkaufsladen, QDistinct> distinctByExcludedItems(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'excludedItems',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QDistinct> distinctByImagePath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'imagePath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Einkaufsladen, Einkaufsladen, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }
}

extension EinkaufsladenQueryProperty
    on QueryBuilder<Einkaufsladen, Einkaufsladen, QQueryProperty> {
  QueryBuilder<Einkaufsladen, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Einkaufsladen, String?, QQueryOperations>
      excludedItemsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'excludedItems');
    });
  }

  QueryBuilder<Einkaufsladen, String?, QQueryOperations> imagePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'imagePath');
    });
  }

  QueryBuilder<Einkaufsladen, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }
}
