import 'package:cloud_firestore/cloud_firestore.dart'; // Make sure this is imported
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../details/comments.dart';
import '../details/event_hall_package.dart';
import '../details/message.dart';
import '../service/database.dart'; // Import the DatabaseService

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
  final DatabaseService _databaseService = DatabaseService(); // Initialize DatabaseService

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    // Listen for auth state changes to keep _currentUser updated and potentially
    // save/update user profile in Firestore
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) { // Check if widget is still mounted
        setState(() {
          _currentUser = user;
        });
        if (user != null) {
          // Save or update user profile in Firestore when auth state changes
          // You might want to get name/phone from user input or default values
          _databaseService.saveUser(user, user.displayName, user.phoneNumber, 'user');
        }
      }
    });
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    _daysController.dispose();
    _personsController.dispose();
    super.dispose();
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
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
        _endDateController.text = DateFormat('yyyy-MM-dd').format(_endDate!);
      });
    }
  }

  void _confirmBooking() async { // Made async to await database operations
    if (_formKey.currentState!.validate()) {
      if (_currentUser == null) {
        // This case should ideally be handled by the UI before calling _confirmBooking
        // but it's good to have a safeguard.
        if (mounted) { // Guard for context
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to confirm your booking!')),
          );
        }
        return;
      }

      // Calculate days if not directly entered, or ensure _daysController is populated
      int days = int.tryParse(_daysController.text) ?? 0;
      if (_startDate != null && _endDate != null) {
        days = _endDate!.difference(_startDate!).inDays + 1;
        _daysController.text = days.toString(); // Update controller with calculated value
      }

      // Prepare booking data
      Map<String, dynamic> bookingData = {
        'userId': _currentUser!.uid,
        'eventHallPackageId': widget.eventHallPackage.id,
        'eventName': widget.eventHallPackage.name,
        'eventPrice': widget.eventHallPackage.price,
        'details': 'Booking for ${widget.eventHallPackage.name}', // Or allow user to input more details
        'visitorPax': int.parse(_personsController.text),
        'startDate': _startDate != null ? Timestamp.fromDate(_startDate!) : null,
        'endDate': _endDate != null ? Timestamp.fromDate(_endDate!) : null,
        'days': days,
        'addOns': [], // Implement UI to select add-ons if needed
        'totalPrice': widget.eventHallPackage.price * days, // Basic calculation, adjust based on add-ons
        'bookingDate': FieldValue.serverTimestamp(),
        'status': 'pending', // Initial status
      };

      try {
        await _databaseService.addBooking(bookingData);
        if (mounted) { // Guard for context
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking Confirmed and Saved!')),
          );
        }
        print('Booking confirmed and saved to Firestore!');
      } catch (e) {
        if (mounted) { // Guard for context
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save booking: $e')),
          );
        }
        print('Error saving booking: $e');
      }
    }
  }

  Future<void> _addMessage(String message) async {
    // ... existing message adding logic ...
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print('User not logged in. Cannot add message.');
      if (mounted) { // Guard for context
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
    // No need for a mounted check here if no context-dependent operations follow this await.
    // However, if you added a success SnackBar here, you would need it.
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
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),


              Text(widget.eventHallPackage.description),
              const SizedBox(height: 8),


              Text('Price: RM${widget.eventHallPackage.price.toStringAsFixed(2)}'),
              const SizedBox(height: 16),


              const Text(
                'Discussion',
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
                          timestamp: data['timestamp'] != null ? 
                          data['timestamp'].toDate() :DateTime.now(),
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

              const SizedBox(height: 16),

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
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Days',
                              hintText: 'e.g., 1, 2, 3',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.timelapse),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Days';
                              }
                              if (int.tryParse(value) == null ||
                                  int.parse(value) <= 0) {
                                return 'Valid Days';
                              }
                              return null;
                            },
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