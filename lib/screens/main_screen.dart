import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shopping_cart/screens/priority_screen.dart';
import 'package:shopping_cart/screens/list_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _State();
}

class _State extends State<MainScreen> {
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          PriorityScreen(),
          ListScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        showSelectedLabels: true,
        showUnselectedLabels: true,
        currentIndex: _selectedIndex,
        backgroundColor: Colors.grey[100],
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.gift),
            label: "품목 관리",
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.shoppingCart),
            label: "장바구니 목록",
          ),
        ],
      ),
    );
  }
}
