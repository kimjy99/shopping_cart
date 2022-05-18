import 'package:flutter/material.dart';

class FloorNameCard extends StatelessWidget {
  const FloorNameCard({Key? key, required this.title, this.color = const Color(0xFF999999)}) : super(key: key);

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      width: double.infinity,
      padding: const EdgeInsets.only(left: 5),
      child: Text(title),
    );
  }
}
