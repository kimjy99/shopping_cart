import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shopping_cart/components/floor_name_card.dart';

class PriorityDeleteScreen extends StatefulWidget {
  const PriorityDeleteScreen({Key? key, required this.items}) : super(key: key);

  final List<String> items;

  @override
  State<PriorityDeleteScreen> createState() => _PriorityDeleteScreenState();
}

class _PriorityDeleteScreenState extends State<PriorityDeleteScreen> {
  List<bool> _isChecked = [];
  bool _isAllChecked = false;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.items.length; i++) {
      _isChecked.add(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("품목 삭제"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          CupertinoButton(
            child: Text("${_isChecked.where((c) => c).toList().length}개 삭제"),
            onPressed: () {
              if (_isChecked.where((c) => c).toList().isNotEmpty) {
                checkDialog();
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
                _buildTopCard(),
                ...filteredItemList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void checkDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            title: const Text("정말 삭제하시겠습니까?"),
            content: Text("[선택한 항목]\n${widget.items.where((i) => _isChecked[widget.items.indexOf(i)]).join(", ")}"),
            actions: [
              CupertinoButton(
                child: const Text("확인"),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, _isChecked);
                },
              ),
              CupertinoButton(
                child: const Text("취소"),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        });
  }

  List<Widget> filteredItemList() {
    return List.generate(widget.items.length, (index) {
      String key = widget.items[index];
      if (key.contains("FLOOR")) {
        return FloorNameCard(title: "${key.substring(key.length - 1, key.length)}층");
      } else {
        return _buildItemCard(index);
      }
    });
  }

  Widget _buildItemCard(index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.items[index],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Checkbox(
              value: _isChecked[index],
              onChanged: (value) {
                setState(() {
                  _isChecked[index] = value!;
                  if (_isChecked.where((c) => c).toList().length == _isChecked.length - 2) {
                    _isAllChecked = true;
                  } else {
                    _isAllChecked = false;
                  }
                });
              })
        ],
      ),
    );
  }

  Widget _buildTopCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(),
          ),
          const Text("전체 선택"),
          Checkbox(
              value: _isAllChecked,
              onChanged: (value) {
                setState(() {
                  _isAllChecked = value!;
                  for (int i = 0; i < _isChecked.length; i++) {
                    if (!widget.items[i].contains("FLOOR")) {
                      _isChecked[i] = value;
                    }
                  }
                });
              })
        ],
      ),
    );
  }
}
