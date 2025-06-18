class EventHallPackage {
  final String id;
  final String title;
  final String description;
  final String image;
<<<<<<< morning2
  final double price;
  // final String customPrice; // Removed customPrice

  final List<String> availableAddOns;
=======
  final double price; 
  final String customPrice;
>>>>>>> main

  const EventHallPackage({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.price,
<<<<<<< morning2
    // required this.customPrice, // Removed from constructor
    this.availableAddOns = const [],
=======
    required this.customPrice,
>>>>>>> main
  });

  String get name => title;
}
