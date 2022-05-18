import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shopping_cart/models/item.dart';
import 'package:shopping_cart/models/return_value.dart';
import 'package:shopping_cart/models/shop.dart';
import 'package:shopping_cart/components/floor_name_card.dart';
import 'package:shopping_cart/screens/load_item_dialog.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({Key? key, this.title = "", this.id = -1, required this.shops, required this.shopReverse})
      : super(key: key);

  final String title;
  final int id;
  final List<Shop> shops;
  final bool shopReverse;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  String title = ""; // 장바구니 이름
  List<String> items = []; // 장바구니에 담긴 품목들
  List<String> checks = []; // 장바구니에서 체크된 품목들
  Map<String, Item> itemMatch = {}; // 품목의 floor, prior 값을 가져오기 위한 map
  List<int> counts = [0, 0, 0, 0]; // 층별 품목 개수 (0: 미지정)
  Map<String, bool> isChecked = {};
  bool isNewShop = false;

  late SharedPreferences prefs;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    title = widget.title;
    if (title.isEmpty) {
      title = DateFormat('yyyy년 MM월 dd일').format(DateTime.now());
      isNewShop = true;
    } else {
      _titleController.text = title;
    }
    _loadItemMatch();
    _loadItems(widget.id);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  void _loadItems(int id) async {
    prefs = await SharedPreferences.getInstance();

    setState(() {
      if (isNewShop) prefs.remove('item_$id');
      items = prefs.getStringList('item_$id') ?? [];
      checks = prefs.getStringList('item_check_$id') ?? [];
      _sortItem();
      for (String s in items) {
        changeCounts(s, 1);
      }
    });
  }

  void _loadItemMatch() async {
    List<String> tempStr = [];
    List<String> itemMatchStr = [];

    prefs = await SharedPreferences.getInstance();
    itemMatchStr = (prefs.getStringList('itemMatch') ?? []);

    setState(() {
      for (String s in itemMatchStr) {
        tempStr = s.split("_");
        itemMatch[tempStr[0]] = Item(name: tempStr[0], prior: int.parse(tempStr[1]), floor: int.parse(tempStr[2]));
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CupertinoTextField(
          placeholder: title,
          controller: _titleController,
          maxLines: 1,
          style: const TextStyle(fontSize: 20),
          onSubmitted: _changeTitle,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 1.0,
        actions: [
          CupertinoButton(
            child: const Text("저장"),
            onPressed: _addShop,
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                child: Text("다른 장바구니 불러오기"),
                value: 1,
              ),
              const PopupMenuItem(
                child: Text("전체 품목에서 선택하기"),
                value: 2,
              ),
            ],
            onSelected: (selected) async {
              if (selected == 1) {
                _loadOtherShop();
              } else if (selected == 2) {
                _loadAllItems();
              }
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
              child: ListView(
            children: [
              if (counts[3] > 0) const FloorNameCard(title: "3층"),
              ...filteredItemList(3),
              if (counts[2] > 0) const FloorNameCard(title: "2층"),
              ...filteredItemList(2),
              if (counts[1] > 0) const FloorNameCard(title: "1층"),
              ...filteredItemList(1),
              if (counts[0] > 0) const FloorNameCard(title: "미지정"),
              ...List.generate(items.length, (index) {
                if (itemMatch[items[index]] == null) {
                  return _buildItemCard(items[index], index);
                } else {
                  return const SizedBox();
                }
              }),
            ],
          )),
          Container(
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  icon: (_focusNode.hasFocus) ? const Icon(Icons.keyboard_hide) : const Icon(Icons.keyboard),
                  onPressed: () {
                    if (_focusNode.hasFocus) {
                      setState(() {
                        _focusNode.unfocus();
                      });
                    } else {
                      setState(() {
                        _focusNode.requestFocus();
                      });
                    }
                  },
                ),
                Expanded(
                  child: TextField(
                    autofocus: isNewShop,
                    focusNode: _focusNode,
                    controller: _textController,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 20),
                    onSubmitted: _addItem,
                  ),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: const Text("추가"),
                  onPressed: () {
                    _addItem(_textController.text);
                  },
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> filteredItemList(floor) {
    return List.generate(items.length, (index) {
      if (itemMatch[items[index]]?.floor == floor) {
        return _buildItemCard(items[index], index);
      } else {
        return const SizedBox();
      }
    });
  }

  void _changeTitle(text) {
    setState(() {
      title = text;
    });
  }

  // prior 기준으로 Item 정렬
  void _sortItem() {
    items.sort((a, b) {
      bool hasA = itemMatch.containsKey(a);
      bool hasB = itemMatch.containsKey(b);
      if (!hasA && !hasB) {
        return 0;
      } else if (!hasA && hasB) {
        return -1;
      } else if (hasA && !hasB) {
        return 1;
      } else {
        return itemMatch[a]!.prior.compareTo(itemMatch[b]!.prior);
      }
    });
  }

  void changeCounts(String s, int val) {
    if (itemMatch.containsKey(s)) {
      counts[itemMatch[s]!.floor] += val;
    } else {
      counts[0] += val;
    }
  }

  // Item 추가
  void _addItem(String text) async {
    prefs = await SharedPreferences.getInstance();
    _textController.clear();

    setState(() {
      if (text.isNotEmpty) {
        if (items.contains(text)) {
          Fluttertoast.showToast(msg: "이미 존재하는 품목입니다", gravity: ToastGravity.BOTTOM);
        } else {
          items.add(text);
          _sortItem();
          changeCounts(text, 1);
        }
      }
    });
  }

  // Item 제거
  void _removeItem(index) {
    setState(() {
      changeCounts(items[index], -1);
      items.removeAt(index);
      _sortItem();
    });
  }

  // '저장' 버튼 클릭 시 Shop 정보 전달
  void _addShop() {
    if (_titleController.text.isNotEmpty) {
      title = _titleController.text;
    }
    _focusNode.unfocus();
    Navigator.pop(
        context,
        ShopAndItems(
            shop: Shop(id: widget.id, title: title, count: items.length.toString()), items: items, checks: checks));
  }

  void _loadAllItems() async {
    final result = await Navigator.push(
        context, MaterialPageRoute(builder: (context) => LoadItemDialog(itemMatch: itemMatch, items: items)));

    if (result != null) {
      setState(() {
        for (String name in items) {
          changeCounts(name, -1);
        }
        items = [];
        for (String name in result.keys) {
          if (result[name]) {
            _addItem(name);
          }
        }
      });
    }
  }

  void _loadOtherShop() {
    if (widget.shops.length > (isNewShop ? 0 : 1)) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              title: const Text("다른 장바구니 불러오기"),
              content: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: ListView(
                  shrinkWrap: true,
                  children: _buildListView(),
                ),
              ),
              actions: [
                CupertinoButton(
                    child: const Text("취소"),
                    onPressed: () {
                      Navigator.pop(context);
                    }),
              ],
            );
          });
    } else {
      Fluttertoast.showToast(msg: "불러올 수 있는 장바구니가 없습니다");
    }
  }

  List<Widget> _buildListView() {
    List<Widget> myList = List.generate(widget.shops.length, (index) => _buildShopCard(widget.shops[index]));
    if (widget.shopReverse) {
      return List.from(myList.reversed);
    } else {
      return myList;
    }
  }

  Widget _buildItemCard(item, index) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 4, right: 10, bottom: 4),
      child: Row(
        children: [
          Checkbox(
              value: checks.contains(item),
              onChanged: (isChecked) {
                setState(() {
                  if (isChecked!) {
                    checks.add(item);
                  } else {
                    checks.remove(item);
                  }
                });
              }),
          Expanded(
            child: Text(
              item,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: checks.contains(item) ? const Color.fromARGB(255, 200, 200, 200) : Colors.black,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(FontAwesomeIcons.trash, color: Colors.grey),
            onPressed: () {
              _removeItem(index);
            },
          )
        ],
      ),
    );
  }

  Widget _buildShopCard(shop) {
    if (widget.id == shop.id) {
      return const SizedBox();
    } else {
      return InkWell(
        onTap: () async {
          Navigator.pop(context);
          _loadItems(shop.id);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  shop.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                "${shop.count}개의 항목",
                style: const TextStyle(color: Color(0xFFa5a5a5), fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }
  }
}
