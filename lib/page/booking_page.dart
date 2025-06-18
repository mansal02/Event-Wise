import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../details/comments.dart';
import '../details/event_hall_package.dart';
import '../details/message.dart';
import '../service/database.dart';

class BookingPage extends StatefulWidget {
  final EventHallPackage eventHallPackage;

  const BookingPage({super.key, required this.eventHallPackage});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();
  final TextEditingController _personsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  User? _currentUser;
  final DatabaseService _databaseService = DatabaseService();

  // Define ALL possible add-ons with their prices
  final Map<String, double> _allPossibleAddOns = {
    'Catering': 1500.0,
    'Emcee': 500.0,
    'DJ': 800.0,
    'Sound System': 700.0,
    'Lighting System': 600.0,
  };

  // Define which add-ons are allowed for each package ID
  // This is the core logic based on your requirements
  final Map<String, List<String>> _packageAddOnMapping = {
    'EH-a-1': ['Catering', 'Emcee', 'DJ', 'Sound System', 'Lighting System'], // Empty Hall
    'EH-b-1': ['Sound System', 'DJ', 'Catering'], // Wedding Package
    'EH-c-1': ['Catering', 'Lighting System', 'DJ'], // Corporate Package
    'EH-d-1': ['Catering'], // Party Package
    'EH-e-1': ['Catering', 'Emcee', 'DJ', 'Sound System', 'Lighting System'], // Custom Package
  };

  // This map will store only the add-ons allowed for the current package, with their prices
  late Map<String, double> _currentPackageAllowedAddOns;
  // This map will store the selected state (true/false) for only the add-ons allowed for the current package
  final Map<String, bool> _selectedAddOns = {};

  // State variable for dynamically calculated total price
  double _currentCalculatedTotalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
        if (user != null) {
          _databaseService.saveUser(user, user.displayName, user.phoneNumber, 'user');
        }
      }
    });

    _initializeAddOnsForCurrentPackage(); // Initialize add-ons specific to this package

    _personsController.addListener(_updateTotalPrice);
    _updateTotalPrice(); // Initial calculation
  }

  // New method to set up add-ons based on the current event package
  void _initializeAddOnsForCurrentPackage() {
    _currentPackageAllowedAddOns = {};
    _selectedAddOns.clear(); // Clear any previous selections

    String packageId = widget.eventHallPackage.id;
    List<String> allowedNames = _packageAddOnMapping[packageId] ?? [];

    for (String addOnName in allowedNames) {
      if (_allPossibleAddOns.containsKey(addOnName)) {
        _currentPackageAllowedAddOns[addOnName] = _allPossibleAddOns[addOnName]!;
        _selectedAddOns[addOnName] = false; // Initialize all allowed add-ons as unselected
      }
    }
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    // _daysController.removeListener(_updateTotalPrice); // Not needed as it's readOnly and updated via date pickers
    _daysController.dispose();

    _personsController.removeListener(_updateTotalPrice);

    _personsController.dispose();
    super.dispose();
  }

  void _updateTotalPrice() {
    double basePrice = widget.eventHallPackage.price;
    int days = int.tryParse(_daysController.text) ?? 1;
    int persons = int.tryParse(_personsController.text) ?? 1;

    double packageCost = basePrice * days;

    double addOnCost = 0.0;
    _selectedAddOns.forEach((name, isSelected) {
      if (isSelected) {
        // Use the price from _allPossibleAddOns for consistency and safety
        addOnCost += _allPossibleAddOns[name] ?? 0.0;
      }
    });

    double perPersonCost = persons * 4.0;

    setState(() {
      _currentCalculatedTotalPrice = packageCost + addOnCost + perPersonCost;
    });
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;

        _startDateController.text = DateFormat('yyyy-MM-dd').format(_startDate!);
        if (_endDate != null && _startDate != null && _startDate!.isBefore(_endDate!)) {
          int calculatedDays = _endDate!.difference(_startDate!).inDays + 1;
          _daysController.text = calculatedDays.toString();
        } else if (_startDate != null && _endDate == null) {
          _daysController.text = '1'; // Default to 1 day if only start date selected
        }
        _updateTotalPrice();
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
        _endDateController.text = DateFormat('yyyy-MM-dd').format(_endDate!);

        if (_startDate != null && _endDate != null) {
          int calculatedDays = _endDate!.difference(_startDate!).inDays + 1;
          _daysController.text = calculatedDays.toString();
        }
        _updateTotalPrice();
      });
    }
  }

  void _confirmBooking() async {
    if (_formKey.currentState!.validate()) {
      if (_currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to confirm your booking!'),
            ),
          );
        }
        return;
      }

      int days = int.tryParse(_daysController.text) ?? 1;
      int persons = int.tryParse(_personsController.text) ?? 0;

      List<String> selectedAddOnNames = _selectedAddOns.keys.where((name) => _selectedAddOns[name]!).toList();

      Map<String, dynamic> bookingData = {
        'userId': _currentUser!.uid,
        'eventHallPackageId': widget.eventHallPackage.id,
        'eventName': widget.eventHallPackage.name,
        'eventPrice': widget.eventHallPackage.price,
        'details': 'Booking for ${widget.eventHallPackage.name}',
        'visitorPax': persons,
        'startDate': _startDate != null ? Timestamp.fromDate(_startDate!) : null,
        'endDate': _endDate != null ? Timestamp.fromDate(_endDate!) : null,
        'days': days,
        'addOns': selectedAddOnNames, // Save only the selected add-on names
        'totalPrice': _currentCalculatedTotalPrice,
        'bookingDate': FieldValue.serverTimestamp(),
        'status': 'pending',
      };

      try {
        await _databaseService.addBooking(bookingData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking Confirmed and Saved!')),
          );
        }
        print('Booking confirmed and saved to Firestore!');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save booking: $e')),
          );
        }
        print('Error saving booking: $e');
      }
    }
  }

  Future<void> _addMessage(String message) async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print('User not logged in. Cannot add message.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to add a message.')),
        );
      }
      return;
    }

    final String discussionId = widget.eventHallPackage.id;

    await FirebaseFirestore.instance
        .collection('discussions')
        .doc(discussionId)
        .collection('messages')
        .add({
      'message': message,
      'sender': user.displayName ?? user.email ?? 'Anonymous',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<ApplicationState>(context);
    final String discussionId = widget.eventHallPackage.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                widget.eventHallPackage.image,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 16),
              Text(
                widget.eventHallPackage.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(widget.eventHallPackage.description),
              const SizedBox(height: 8),
              Text('Base Price Per Day: RM${widget.eventHallPackage.price.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              const Text(
                'Reviews and Discussion',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              SizedBox(
                height: 300,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('discussions')
                      .doc(discussionId)
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text('No messages yet. Start the discussion!'),
                      );
                    }

                    return ListView(
                      reverse: true,
                      children: snapshot.data!.docs.map((document) {
                        Map<String, dynamic> data =
                            document.data() as Map<String, dynamic>;
                        return MessageCard(
                          message: data['message'],
                          sender: data['sender'],
                          timestamp: data['timestamp'] != null
                              ? data['timestamp'].toDate()
                              : DateTime.now(),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
              // Always display the Comments widget, but control its functionality internally
              Comments(
                addMessage: _addMessage,
                canComment: _currentUser != null && appState.loggedIn, // This looks correct
              ),
              const SizedBox(height: 24),

              // --- Add-ons Section ---
              // Only display this section if there are allowed add-ons for the current package
              if (_currentPackageAllowedAddOns.isNotEmpty) ...[
                const Text(
                  'Event Add-ons',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                ..._currentPackageAllowedAddOns.keys.map((addOnName) {
                  return CheckboxListTile(
                    title: Text('$addOnName (RM${_currentPackageAllowedAddOns[addOnName]?.toStringAsFixed(2)})'),
                    value: _selectedAddOns[addOnName],
                    onChanged: (bool? newValue) {
                      setState(() {
                        _selectedAddOns[addOnName] = newValue!;
                        _updateTotalPrice(); // Update total price when add-ons change
                      });
                    },
                  );
                }).toList(),
                const SizedBox(height: 24),
              ],
              // --- End Add-ons Section ---

              const Text(
                'Booking Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _startDateController,
                            readOnly: true,
                            onTap: () => _selectStartDate(context),
                            decoration: const InputDecoration(
                              labelText: 'Start Date',
                              hintText: 'Select Start Date',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a start date';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _endDateController,
                            readOnly: true,
                            onTap: () => _selectEndDate(context),
                            decoration: const InputDecoration(
                              labelText: 'End Date',
                              hintText: 'Select End Date',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select an end date';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _daysController,
                            readOnly: true,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Days',
                              hintText: 'Calculated from dates',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.timelapse),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _personsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Pax',
                              hintText: 'e.g., 50, 100, 200',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.people),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Pax';
                              }
                              if (int.tryParse(value) == null ||
                                  int.parse(value) <= 0) {
                                return 'Valid Pax';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Estimated Total: RM${_currentCalculatedTotalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: appState.loggedIn
                            ? _confirmBooking
                            : () => context.go('/sign-in'),
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(
                          appState.loggedIn
                              ? 'Confirm Booking'
                              : 'Login to Confirm',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                          textStyle: const TextStyle(fontSize: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}