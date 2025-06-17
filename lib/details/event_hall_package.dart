class EventHallPackage {
  final String id;
  final String title;
  final String description;
  final String image;
  final double price; 

  const EventHallPackage({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.price,
  });

  String get name => title;
}