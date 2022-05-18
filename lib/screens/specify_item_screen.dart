import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopping_cart/models/item.dart';
import 'package:shopping_cart/models/return_value.dart';

class SpecifyItemScreen extends StatefulWidget {
  const SpecifyItemScreen({Key? key, required this.itemMatch}) : super(key: key);

  final Map<String, Item> itemMatch;

  @override
  State<SpecifyItemScreen> createState() => _SpecifyItemScreenState();
}

class _SpecifyItemScreenState extends State<SpecifyItemScreen> {
  final _floorList = ["3층", "2층", "1층"];
  List<String> shops = [];
  List<bool> shopCheck = []; // checkbox of shops
  Map<String, List<String>> shop2items = {}; // key: shop, value: items
  Map<String, String> itemFloor = {}; // key: item, value: floor of items
  Map<String, bool> itemCheck = {}; // key: item, value: checkbox of items
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  _loadShops() async {
    List<String> tempStr = [];
    prefs = await SharedPreferences.getInstance();

    List<String> shopStrs = prefs.getStringList('shops') ?? [];

    setState(() {
      for (int i = 0; i < shopStrs.length; i++) {
        tempStr = shopStrs[i].split("_");
        int id = int.parse(tempStr[0]);
        String title = tempStr[1];
        List<String> items =
            (prefs.getStringList('item_$id') ?? []).where((item) => widget.itemMatch[item] == null).toList();
        if (items.isNotEmpty) {
          shop2items[title] = items;
          shops.add(title);
          shopCheck.add(false);
          for (String item in items) {
            itemCheck[item] = false;
            itemFloor[item] = "1층";
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("미지정 품목 불러오기"),
        elevation: 1.0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          CupertinoButton(
              child: const Text("확인"),
              onPressed: () {
                Navigator.pop(context, ItemCheckAndFloor(itemCheck: itemCheck, itemFloor: itemFloor));
              }),
        ],
      ),
      body: ListView(children: List.generate(shops.length, (index) => _buildSelectionCard(index))),
    );
  }

  Widget _buildSelectionCard(int idx) {
    String title = shops[idx];
    return ListView(
      shrinkWrap: true,
      children: [
        _buildShopCard(title, idx),
        ...List.generate(shop2items[title]!.length, (index) => _buildItemCard(shop2items[title]![index])),
        Container(height: 1, width: double.infinity, color: Colors.grey),
      ],
    );
  }

  Widget _buildShopCard(String title, int idx) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
          Checkbox(
              value: shopCheck[idx],
              onChanged: (value) {
                setState(() {
                  shopCheck[idx] = value!;
                  for (String item in shop2items[title]!) {
                    itemCheck[item] = value;
                  }
                });
              })
        ],
      ),
    );
  }

  Widget _buildItemCard(String item) {
    return Padding(
      padding: const EdgeInsets.only(left: 25, right: 15),
      child: Row(
        children: [
          Expanded(child: Text(item, style: const TextStyle(fontSize: 16))),
          DropdownButton(
            value: itemFloor[item],
            items: _floorList.map((value) {
              return DropdownMenuItem(value: value, child: Text(value));
            }).toList(),
            onChanged: (itemCheck[item]!)
                ? (value) {
                    setState(() {
                      itemFloor[item] = value.toString();
                    });
                  }
                : null,
          ),
          Checkbox(
            value: itemCheck[item],
            onChanged: (value) {
              setState(() {
                itemCheck[item] = value!;
                for (String shop in shop2items.keys) {
                  List<String> items = shop2items[shop]!;
                  if (items.contains(item)) {
                    if (items.length ==
                        itemCheck.keys.where((s) => itemCheck[s]! && items.contains(s)).toList().length) {
                      shopCheck[shops.indexOf(shop)] = true;
                    } else {
                      shopCheck[shops.indexOf(shop)] = false;
                    }
                  }
                }
              });
            },
          )
        ],
      ),
    );
  }
}
