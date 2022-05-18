class Shop {
  final int id;
  final String title;
  final String count;

  Shop({required this.id, required this.title, required this.count});

  @override
  String toString() {
    return title;
  }
}
