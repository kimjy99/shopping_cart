import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shopping_cart/components/floor_name_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopping_cart/models/item.dart';
import 'package:shopping_cart/screens/priority_delete_screen.dart';
import 'package:shopping_cart/screens/specify_item_screen.dart';

class PriorityScreen extends StatefulWidget {
  const PriorityScreen({Key? key}) : super(key: key);

  @override
  State<PriorityScreen> createState() => _PriorityScreenState();
}

class _PriorityScreenState extends State<PriorityScreen> {
  final TextEditingController _textController = TextEditingController();
  final _floorList = ["3층", "2층", "1층"];
  String _floor = "1층";
  List<int> maxPrior = [0, 0, 0, 0];

  late SharedPreferences prefs;
  late FocusNode _focusNode;

  List<String> itemMatchStr = [];
  Map<String, Item> itemMatch = {};
  List<String> items = [];

  @override
  void initState() {
    super.initState();
    setState(() {
      items.add("FLOOR3");
      items.add("FLOOR2");
      items.add("FLOOR1");
      itemMatch["FLOOR3"] = Item(name: "FLOOR3", prior: 10000, floor: 4);
      itemMatch["FLOOR2"] = Item(name: "FLOOR2", prior: 10000, floor: 3);
      itemMatch["FLOOR1"] = Item(name: "FLOOR1", prior: 10000, floor: 2);
      itemMatch["FLOOR0"] = Item(name: "FLOOR1", prior: 10000, floor: 1);
    });
    _loadItemMatch();
    _focusNode = FocusNode();
  }

  /*      floor prior
  *         3     1
  *         3     2
  * FLOOR2  3     10000
  *         2     1
  *         2     2
  * FLOOR1  2     10000
  *         1     1
  *         1     2
  * FLOOR0  1     10000
  */

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  _loadItemMatch() async {
    List<String> tempStr = [];
    prefs = await SharedPreferences.getInstance();
    itemMatchStr = (prefs.getStringList('itemMatch') ?? []);

    setState(() {
      for (String s in itemMatchStr) {
        tempStr = s.split("_");
        String name = tempStr[0];
        int prior = int.parse(tempStr[1]);
        int floor = int.parse(tempStr[2]);
        itemMatch[name] = Item(name: name, prior: prior, floor: floor);
        items.add(name);
        maxPrior[floor] = max(maxPrior[floor], prior);
      }
      _sortItem();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("품목 관리"),
        elevation: 1.0,
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                child: Text("품목 삭제"),
                value: 1,
                padding: EdgeInsets.only(left: 10.0),
              ),
              const PopupMenuItem(
                child: Text("미지정 품목 불러오기"),
                value: 2,
                padding: EdgeInsets.only(left: 10.0),
              ),
            ],
            onSelected: (selected) async {
              if (selected == 1) {
                final result = await Navigator.push(
                    context, MaterialPageRoute(builder: (context) => PriorityDeleteScreen(items: items)));

                if (result != null) {
                  List<String> names = [];
                  for (int i = 0; i < result.length; i++) {
                    if (result[i]) {
                      names.add(items[i]);
                    }
                  }
                  for (String name in names) {
                    _removeItem(name);
                  }
                  Fluttertoast.showToast(msg: "${names.join(", ")} 삭제 완료");
                }
              } else if (selected == 2) {
                final result = await Navigator.push(
                    context, MaterialPageRoute(builder: (context) => SpecifyItemScreen(itemMatch: itemMatch)));

                if (result != null) {
                  String tempFloor = _floor;
                  for (String name in result.itemCheck.keys) {
                    if (result.itemCheck[name]) {
                      _floor = result.itemFloor[name] ?? "1층";
                      _addItem(name);
                    }
                  }
                  _floor = tempFloor;
                }
              }
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Text(itemMatchStr.join(", ")), // 테스트용
          Expanded(child: filteredItemList()),
          Container(
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    focusNode: _focusNode,
                    controller: _textController,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 20),
                    onSubmitted: _addItem,
                  ),
                ),
                DropdownButton(
                    value: _floor,
                    items: _floorList.map((value) {
                      return DropdownMenuItem(value: value, child: Text(value));
                    }).toList(),
                    onTap: () {
                      if (_focusNode.hasFocus) {
                        _focusNode.requestFocus();
                      }
                    },
                    onChanged: (value) {
                      setState(() {
                        _floor = value.toString();
                      });
                    }),
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

  Widget filteredItemList() {
    return ReorderableListView(
      shrinkWrap: true,
      buildDefaultDragHandles: false,
      children: List.generate(items.length, (index) {
        String key = items[index];
        if (key.contains("FLOOR")) {
          return ReorderableDragStartListener(
            child: FloorNameCard(title: "${key.substring(key.length - 1, key.length)}층"),
            index: index,
            key: ValueKey(index),
          );
        } else {
          return _buildItemCard(index, itemMatch[key]);
        }
      }),
      onReorder: (int oldIndex, int newIndex) {
        setState(() {
          String oldName = items[oldIndex];
          String newName = newIndex < items.length ? items[newIndex] : "FLOOR0";

          Item oldItem = Item.clone(itemMatch[oldName]!);
          Item newItem = Item.clone(itemMatch[newName]!);

          if (!oldName.startsWith("FLOOR") && oldIndex != newIndex && newIndex > 0) {
            if (newItem.floor != oldItem.floor) {
              // Floor changes
              for (String key in itemMatch.keys) {
                Item value = itemMatch[key]!;
                if (value.floor == oldItem.floor && value.prior > oldItem.prior) {
                  if (value.prior < 10000) {
                    setItemMatchPrior(key, value.prior - 1);
                  }
                }
                if (value.floor == newItem.floor && value.prior >= newItem.prior) {
                  if (value.prior < 10000) {
                    setItemMatchPrior(key, value.prior + 1);
                  }
                }
              }
              maxPrior[oldItem.floor]--;
              maxPrior[newItem.floor]++;
              setItemMatchFloor(oldName, newItem.floor);
              if (newItem.prior < 10000) {
                setItemMatchPrior(oldName, newItem.prior);
              } else {
                setItemMatchPrior(oldName, maxPrior[newItem.floor]);
              }
            } else {
              // Floor not changes
              if (oldIndex > newIndex) {
                // Widget goes up
                for (String key in itemMatch.keys) {
                  Item value = itemMatch[key]!;
                  if (value.floor == oldItem.floor && value.prior < oldItem.prior && value.prior >= newItem.prior) {
                    setItemMatchPrior(key, value.prior + 1);
                  }
                }
                setItemMatchPrior(oldName, newItem.prior);
              } else {
                // Widget goes down
                Item newItem = Item.clone(itemMatch[items[newIndex - 1]]!);
                for (String key in itemMatch.keys) {
                  Item value = itemMatch[key]!;
                  if (value.floor == oldItem.floor && value.prior > oldItem.prior && value.prior <= newItem.prior) {
                    setItemMatchPrior(key, value.prior - 1);
                  }
                }
                setItemMatchPrior(oldName, newItem.prior);
              }
            }
            if (oldIndex < newIndex) {
              newIndex--;
            }
            items.removeAt(oldIndex);
            items.insert(newIndex, oldName);
            prefs.setStringList('itemMatch', itemMatchStr);
          }
        });
      },
    );
  }

  void setItemMatchPrior(String name, int prior) {
    int index = itemMatchStr.indexWhere((s) => s.split("_")[0] == name);
    itemMatchStr[index] = "${name}_${prior}_${itemMatch[name]!.floor}";
    itemMatch[name]!.prior = prior;
  }

  void setItemMatchFloor(String name, int floor) {
    int index = itemMatchStr.indexWhere((s) => s.split("_")[0] == name);
    itemMatchStr[index] = "${name}_${itemMatch[name]!.prior}_$floor";
    itemMatch[name]!.floor = floor;
  }

  // floor & prior 기준으로 Item 정렬
  void _sortItem() {
    items.sort((a, b) {
      if (itemMatch[a]!.floor < itemMatch[b]!.floor) {
        return 1;
      } else if (itemMatch[a]!.floor > itemMatch[b]!.floor) {
        return -1;
      } else {
        return itemMatch[a]!.prior.compareTo(itemMatch[b]!.prior);
      }
    });
  }

  void _addItem(String text) {
    _textController.clear();
    if (text.isNotEmpty) {
      if (itemMatch.containsKey(text)) {
        Fluttertoast.showToast(msg: "이미 존재하는 품목입니다", gravity: ToastGravity.BOTTOM);
      } else {
        int floor = int.parse(_floor.substring(0, 1));
        maxPrior[floor]++;
        Item newItem = Item(name: text, prior: maxPrior[floor], floor: floor);
        setState(() {
          itemMatchStr.add("${text}_${maxPrior[floor]}_$floor");
          itemMatch[text] = newItem;
          items.add(text);
        });
        prefs.setStringList('itemMatch', itemMatchStr);
        _sortItem();
      }
    }
  }

  void _removeItem(String name) {
    Item target = Item.clone(itemMatch[name]!);
    maxPrior[target.floor] = max(maxPrior[target.floor] - 1, 0);

    setState(() {
      for (String key in itemMatch.keys) {
        Item value = itemMatch[key]!;
        if (value.floor == target.floor && value.prior > target.prior) {
          if (value.prior < 10000) {
            setItemMatchPrior(key, value.prior - 1);
          }
        }
      }
      itemMatch.remove(name);
      itemMatchStr.removeWhere((s) => s.split("_")[0] == name);
      items.remove(name);
    });

    prefs.setStringList('itemMatch', itemMatchStr);
  }

  Widget _buildItemCard(index, item) {
    return Padding(
      key: ValueKey(index),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_handle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(FontAwesomeIcons.trash, color: Colors.grey),
            onPressed: () {
              _removeItem(item.name);
              Fluttertoast.showToast(msg: "${item.name} 삭제 완료");
            },
          )
        ],
      ),
    );
  }
}
