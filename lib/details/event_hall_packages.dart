//event_hall_packages.dart
import 'event_hall_package.dart';

// Define a central list of all available add-ons
final List<String> _allAvailableAddOns = const [
  'Catering',
  'Emcee',
  'DJ',
  'Sound System',
  'Lighting System',
];

final List<EventHallPackage> eventHallPackages = [
  // REMOVED 'const' from here
  EventHallPackage(
    // KEEP 'const' for individual package instances
    id: 'EH-a-1',
    title: 'Empty Hall Rental',
    description:
        'A spacious ballroom with no additional services. Ideal for full customization.',
    image: 'assets/images/BallRoomEmpty.png',
    price: 5000.0,
    availableAddOns: _allAvailableAddOns, // All add-ons available
  ),
  EventHallPackage(
    // KEEP 'const' for individual package instances
    id: 'EH-b-1',
    title: 'Wedding Package',
    description:
        'A luxurious wedding setup with decor, emcee, lighting, and seating.',
    image: 'assets/images/BallRoomWedding.png',
    price: 9000.0,
    availableAddOns: _allAvailableAddOns, // All add-ons available
  ),
  EventHallPackage(
    // KEEP 'const' for individual package instances
    id: 'EH-c-1',
    title: 'Corporate Package',
    description:
        'Professional setup with projector, emcee, PA system, stage, and refreshments.',
    image: 'assets/images/BallRoomCorporate.png',
    price: 7000.0,
    availableAddOns: _allAvailableAddOns, // All add-ons available
  ),
  EventHallPackage(
    // KEEP 'const' for individual package instances
    id: 'EH-d-1',
    title: 'Party Package',
    description:
        'Includes DJ, emcee, ambient lighting, dance floor setup, and seating arrangement.',
    image: 'assets/images/BallRoomParty.png',
    price: 8500.0,
    availableAddOns: _allAvailableAddOns, // All add-ons available
  ),
  EventHallPackage(
    // KEEP 'const' for individual package instances
    id: 'EH-e-1',
    title: 'Custom Package',
    description:
        'Create your own experience with all the amenities you need, additional costs may apply based on selected services.',
    image: 'assets/images/BallRoomPersonalised.png',
    price: 6000.0,
    availableAddOns: _allAvailableAddOns, // All add-ons available
  ),
];
