import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopping_cart/models/shop.dart';
import 'package:shopping_cart/screens/list_delete_screen.dart';
import 'package:shopping_cart/screens/shop_screen.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({Key? key}) : super(key: key);

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  List<Shop> shops = [];
  List<String> shopStrs = [];
  late SharedPreferences prefs;
  int lastId = 0;
  bool shopReverse = false;

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  _loadShops() async {
    List<String> tempStr = [];
    int tempId = 0;
    prefs = await SharedPreferences.getInstance();

    shopStrs = prefs.getStringList('shops') ?? [];

    setState(() {
      for (int i = 0; i < shopStrs.length; i++) {
        tempStr = shopStrs[i].split("_");
        tempId = int.parse(tempStr[0]);
        shops.add(Shop(id: tempId, title: tempStr[1], count: tempStr[2]));
        lastId = max(lastId, tempId);
      }
      shopReverse = prefs.getBool('shopReverse') ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("장바구니 목록"),
        elevation: 1.0,
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Text("${shopReverse ? "오래된" : "최신"} 순으로 정렬"),
                value: 1,
                padding: const EdgeInsets.only(left: 10.0),
              ),
              const PopupMenuItem(
                child: Text("장바구니 삭제"),
                value: 2,
                padding: EdgeInsets.only(left: 10.0),
              ),
            ],
            onSelected: (selected) async {
              if (selected == 1) {
                setState(() {
                  shopReverse = !shopReverse;
                });
                prefs.setBool('shopReverse', shopReverse);
              } else if (selected == 2) {
                final result = await Navigator.push(
                    context, MaterialPageRoute(builder: (context) => ListDeleteScreen(shops: shops)));
                FocusManager.instance.primaryFocus?.unfocus();
                if (result != null) {
                  for (int i = result.length - 1; i >= 0; i--) {
                    if (result[i]) {
                      _removeShop(i);
                    }
                  }
                }
              }
            },
          )
        ],
      ),
      body: ListView(
        children: _buildListView(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _makeNewShop,
        child: const Icon(Icons.add_shopping_cart),
      ),
    );
  }

  List<Widget> _buildListView() {
    List<Widget> myList = List.generate(shops.length, (index) => _buildShopCard(shops[index], index));
    if (shopReverse) {
      return List.from(myList.reversed);
    } else {
      return myList;
    }
  }

  // floatingActionButton 연동
  void _makeNewShop() async {
    idUpdate();
    final result = await Navigator.push(context,
        MaterialPageRoute(builder: (context) => ShopScreen(id: (lastId + 1), shops: shops, shopReverse: shopReverse)));

    if (result != null) {
      setState(() {
        shops.add(result.shop);
      });
      lastId++;
      shopStrs.add("${lastId}_${result.shop.title}_${result.shop.count}");
      prefs.setStringList('shops', shopStrs);
      prefs.setStringList('item_$lastId', result.items);
      prefs.setStringList('item_check_$lastId', result.checks);
    }
  }

  void _removeShop(int index) async {
    bool idCheck = false;
    if (shops[index].id == lastId) {
      idCheck = true;
    }

    setState(() {
      shops.removeAt(index);
    });

    shopStrs.removeAt(index);
    prefs.setStringList('shops', shopStrs);
    prefs.remove('item_${shops[index].id}');

    if (idCheck) idUpdate();
  }

  void idUpdate() {
    lastId = 0;
    for (var shop in shops) {
      lastId = max(lastId, shop.id);
    }
  }

  Widget _buildShopCard(shop, index) {
    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ShopScreen(title: shop.title, id: shop.id, shops: shops, shopReverse: shopReverse),
            ));
        FocusManager.instance.primaryFocus?.unfocus();
        if (result != null) {
          setState(() {
            shops[index] = result.shop;
          });
          shopStrs[index] = "${shop.id}_${result.shop.title}_${result.shop.count}";
          prefs.setStringList('shops', shopStrs);
          prefs.setStringList('item_${shop.id}', result.items);
          prefs.setStringList('item_check_${shop.id}', result.checks);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                shop.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            Text(
              "${shop.count}개의 항목",
              style: const TextStyle(color: Color(0xFFA5A5A5), fontSize: 15),
            ),
            const SizedBox(width: 15),
            IconButton(
              icon: const Icon(FontAwesomeIcons.trash, color: Colors.grey),
              onPressed: () {
                _removeShop(index);
              },
            ),
          ],
        ),
      ),
    );
  }
}
