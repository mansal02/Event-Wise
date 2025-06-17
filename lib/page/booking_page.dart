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

  // Define available add-ons with their prices
  final Map<String, double> _availableAddOns = {
    'Catering': 1500.0,
    'Emcee': 500.0,
    'DJ': 800.0,
    'Sound System': 700.0,
    'Lighting System': 600.0,
  };

  // State to hold selected add-ons
  final Map<String, bool> _selectedAddOns = {
    'Catering': false,
    'Emcee': false,
    'DJ': false,
    'Sound System': false,
    'Lighting System': false,
  };

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

    // Add listeners to text controllers to update total price dynamically
    // _daysController listener is implicitly handled by date selection now
    _personsController.addListener(_updateTotalPrice);
    // Initial calculation when the page loads
    _updateTotalPrice();
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    // _daysController.removeListener(_updateTotalPrice); // Not needed as it's readOnly and updated via date pickers
    _daysController.dispose();
    _personsController.removeListener(_updateTotalPrice); // Remove listener
    _personsController.dispose();
    super.dispose();
  }

  // Method to calculate and update the total price
  void _updateTotalPrice() {
    double basePrice = widget.eventHallPackage.price;
    // Get days from controller, which is updated by date pickers
    int days = int.tryParse(_daysController.text) ?? 1; // Default to 1 day if not entered or calculated yet
    int persons = int.tryParse(_personsController.text) ?? 1; // Default to 1 person if not entered

    // Calculate price based on days (assuming base price is per day)
    double packageCost = basePrice * days;

    // Calculate add-on cost
    double addOnCost = 0.0;
    _selectedAddOns.forEach((name, isSelected) {
      if (isSelected) {
        addOnCost += _availableAddOns[name] ?? 0.0;
      }
    });

    // Calculate per-person cost
    // You can adjust the per-person rate (e.g., RM 10.0 per person)
    double perPersonCost = persons * 10.0; 

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
        // If end date is already selected, recalculate days
        if (_endDate != null && _startDate != null && _startDate!.isBefore(_endDate!)) {
          int calculatedDays = _endDate!.difference(_startDate!).inDays + 1;
          _daysController.text = calculatedDays.toString();
        } else if (_startDate != null && _endDate == null) {
          // If only start date is selected, assume 1 day for initial calculation
          _daysController.text = '1';
        }
        _updateTotalPrice(); // Update total price when dates change
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(), // End date cannot be before start date
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
        _endDateController.text = DateFormat('yyyy-MM-dd').format(_endDate!);
        // Recalculate days and update total price
        if (_startDate != null && _endDate != null) {
          int calculatedDays = _endDate!.difference(_startDate!).inDays + 1;
          _daysController.text = calculatedDays.toString(); // Update days controller
        }
        _updateTotalPrice(); // Update total price when dates change
      });
    }
  }


  void _confirmBooking() async {
    if (_formKey.currentState!.validate()) {
      if (_currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to confirm your booking!')),
          );
        }
        return;
      }

      // Ensure days and persons controllers are updated before final calculation
      int days = int.tryParse(_daysController.text) ?? 1;
      int persons = int.tryParse(_personsController.text) ?? 1;


      // Prepare booking data
      Map<String, dynamic> bookingData = {
        'userId': _currentUser!.uid,
        'eventHallPackageId': widget.eventHallPackage.id,
        'eventName': widget.eventHallPackage.name,
        'eventPrice': widget.eventHallPackage.price, // This is the base price per day/event
        'details': 'Booking for ${widget.eventHallPackage.name}',
        'visitorPax': persons, // Use the parsed persons value
        'startDate': _startDate != null ? Timestamp.fromDate(_startDate!) : null,
        'endDate': _endDate != null ? Timestamp.fromDate(_endDate!) : null,
        'days': days, // Use the parsed days value
        'addOns': _selectedAddOns.keys.where((name) => _selectedAddOns[name]!).toList(),
        'totalPrice': _currentCalculatedTotalPrice, // Use the dynamically calculated total price
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
      appBar: AppBar(
        title: const Text('Booking Details'),
      ),
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

              Text('Base Price Per Day: RM${widget.eventHallPackage.price.toStringAsFixed(2)}'), // Clarified base price label
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
                          child: Text('No messages yet. Start the discussion!'));
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
              if (_currentUser != null && appState.loggedIn)
                Comments(
                  addMessage: _addMessage,
                )
              else
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Login to join the discussion.',
                    style: TextStyle(
                        fontStyle: FontStyle.italic, color: Colors.grey[600]),
                  ),
                ),

              const SizedBox(height: 24),

              // --- Add-ons Section ---
              const Text(
                'Event Add-ons',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              ..._availableAddOns.keys.map((addOnName) {
                return CheckboxListTile(
                  title: Text('$addOnName (RM${_availableAddOns[addOnName]?.toStringAsFixed(2)})'),
                  value: _selectedAddOns[addOnName],
                  onChanged: (bool? newValue) {
                    setState(() {
                      _selectedAddOns[addOnName] = newValue!;
                      _updateTotalPrice(); // Update total price when add-ons change
                    });
                  },
                );
              }).toList(),
              // --- End Add-ons Section ---

              const SizedBox(height: 24),

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
                            readOnly: true, // Made read-only
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Days',
                              hintText: 'Calculated from dates', // Changed hint
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.timelapse),
                            ),
                            // Removed validator as it's no longer user editable
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

                    // --- Dynamic Total Price Display ---
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
                    const SizedBox(height: 16), // Space before button

                    Center(
                      child: ElevatedButton.icon(
                        onPressed: appState.loggedIn
                            ? _confirmBooking
                            : () => context.go('/sign-in'),
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(appState.loggedIn
                            ? 'Confirm Booking'
                            : 'Login to Confirm'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
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
