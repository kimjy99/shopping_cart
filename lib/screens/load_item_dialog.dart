import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shopping_cart/components/floor_name_card.dart';
import 'package:shopping_cart/models/item.dart';

class LoadItemDialog extends StatefulWidget {
  const LoadItemDialog({Key? key, required this.itemMatch, required this.items}) : super(key: key);

  final Map<String, Item> itemMatch;
  final List<String> items;

  @override
  State<LoadItemDialog> createState() => _LoadItemDialogState();
}

class _LoadItemDialogState extends State<LoadItemDialog> {
  Map<String, bool> isChecked = {};

  @override
  void initState() {
    super.initState();
    for (String name in widget.itemMatch.keys) {
      isChecked[name] = widget.items.contains(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("전체 품목에서 선택하기"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                const FloorNameCard(title: "3층"),
                ...filteredAllItemList(3),
                const FloorNameCard(title: "2층"),
                ...filteredAllItemList(2),
                const FloorNameCard(title: "1층"),
                ...filteredAllItemList(1),
              ],
            ),
          ),
          Row(
            children: [
              const Expanded(child: SizedBox()),
              CupertinoButton(
                  child: const Text("확인"),
                  onPressed: () {
                    Navigator.pop(context, isChecked);
                  }),
              CupertinoButton(
                  child: const Text("취소"),
                  onPressed: () {
                    Navigator.pop(context);
                  }),
            ],
          )
        ],
      ),
    );
  }

  List<Widget> filteredAllItemList(floor) {
    return List.generate(widget.itemMatch.keys.length, (index) {
      String key = widget.itemMatch.keys.toList()[index];
      if (widget.itemMatch[key]?.floor == floor) {
        return _buildSelectedItemCard(key);
      } else {
        return const SizedBox();
      }
    });
  }

  Widget _buildSelectedItemCard(item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Checkbox(
            value: isChecked[item],
            onChanged: (value) {
              setState(() {
                isChecked[item] = value!;
              });
            },
          )
          // Checkbox(value: value, onChanged: () {})
        ],
      ),
    );
  }
}
