import 'package:mockito/annotations.dart';
import 'package:smart/services/productgroup_service.dart';
import 'package:isar/isar.dart';
import 'package:smart/objects/productgroup.dart';

@GenerateMocks([ProductGroupService, IsarCollection<Productgroup>, Isar])
void main() {}
