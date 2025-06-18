//event_hall_package.dart
class EventHallPackage {
  final String id;
  final String title;
  final String description;
  final String image;
  final double price;

  final List<String> availableAddOns;

  const EventHallPackage({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.price,
    this.availableAddOns = const [],
  });

  String get name => title;
}
