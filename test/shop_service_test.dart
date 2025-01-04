import 'package:mockito/annotations.dart';
import 'package:smart/services/shop_service.dart';
import 'package:isar/isar.dart';
import 'package:smart/objects/shop.dart';

@GenerateMocks([ShopService, IsarCollection<Einkaufsladen>, Isar])
void main() {}
