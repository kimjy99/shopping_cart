import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shopping_cart/models/shop.dart';

class ListDeleteScreen extends StatefulWidget {
  const ListDeleteScreen({Key? key, required this.shops}) : super(key: key);

  final List<Shop> shops;

  @override
  State<ListDeleteScreen> createState() => _ListDeleteScreenState();
}

class _ListDeleteScreenState extends State<ListDeleteScreen> {
  List<bool> _isChecked = [];
  bool _isAllChecked = false;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.shops.length; i++) {
      _isChecked.add(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("장바구니 삭제"),
        elevation: 1.0,
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
      body: ListView(
        children: [
          _buildTopCard(),
          Container(height: 1, width: double.infinity, color: Colors.grey),
          ...List.generate(widget.shops.length, (index) => _buildShopCard(widget.shops[index], index))
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
            content: Text("[선택한 장바구니]\n${widget.shops.where((i) => _isChecked[widget.shops.indexOf(i)]).join("\n")}"),
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

  Widget _buildShopCard(shop, index) {
    return Padding(
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
            style: const TextStyle(color: Color(0xFFa5a5a5), fontSize: 15),
          ),
          const SizedBox(width: 15),
          Checkbox(
              value: _isChecked[index],
              onChanged: (value) {
                setState(() {
                  _isChecked[index] = value!;
                  if (_isChecked.where((c) => c).toList().length == _isChecked.length) {
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    _isChecked[i] = value;
                  }
                });
              })
        ],
      ),
    );
  }
}
