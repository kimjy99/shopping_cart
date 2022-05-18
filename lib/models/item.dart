class Item {
  final String name;
  int prior;
  int floor;

  Item({required this.name, this.floor = 0, this.prior = 0});

  Item.clone(Item item) : this(name: item.name, floor: item.floor, prior: item.prior);
}
