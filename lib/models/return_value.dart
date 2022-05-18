import 'package:shopping_cart/models/shop.dart';

class ShopAndItems {
  Shop shop;
  List<String> items;
  List<String> checks;

  ShopAndItems({required this.shop, required this.items, required this.checks});
}

class ItemCheckAndFloor {
  Map<String, bool> itemCheck;
  Map<String, String> itemFloor;

  ItemCheckAndFloor({required this.itemCheck, required this.itemFloor});
}
