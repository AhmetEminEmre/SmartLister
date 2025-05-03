import 'package:mockito/annotations.dart';
import 'package:isar/isar.dart';
import 'package:smart/objects/productgroup.dart';

@GenerateMocks(
  [
    Isar,
    IsarCollection<Productgroup>,
  ],
  customMocks: [
    MockSpec<QueryBuilder<Productgroup, Productgroup, QFilterCondition>>(as: #MockQFilterConditionQueryBuilder),
    MockSpec<QueryBuilder<Productgroup, Productgroup, QAfterFilterCondition>>(as: #MockQAfterFilterConditionQueryBuilder),
    MockSpec<QueryBuilder<Productgroup, Productgroup, QAfterSortBy>>(as: #MockQAfterSortByQueryBuilder),
  ],
)
void main() {}
