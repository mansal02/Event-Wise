//booking_edit_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart'; // Import go_router for context.pop()

class BookingEditPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const BookingEditPage({super.key, required this.docId, required this.data});

  @override
  State<BookingEditPage> createState() => _BookingEditPageState();
}

class _BookingEditPageState extends State<BookingEditPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _eventNameController;
  late TextEditingController _visitorPaxController;
  DateTime? _startDate;
  DateTime? _endDate;

  double _currentCalculatedTotalPrice = 0.0;
  double _hallPrice = 0.0; // Variable to hold the hall price

  // Define ALL possible add-ons with their prices (ensure this matches your BookingPage or backend definition)
  final Map<String, double> _allPossibleAddOns = {
    'Catering': 1500.0,
    'Emcee': 500.0,
    'DJ': 800.0,
    'Sound System': 700.0,
    'Lighting System': 600.0,
  };

  // Map to store the selection state of each add-on
  late Map<String, bool> _selectedAddOns;

  @override
  void initState() {
    super.initState();
    _eventNameController = TextEditingController(
      text: widget.data['eventName'],
    );
    _visitorPaxController = TextEditingController(
      text: widget.data['visitorPax'].toString(),
    );
    // Ensure that startDate and endDate are not null before toDate()
    _startDate =
        (widget.data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    _endDate =
        (widget.data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now();

    // The hall price is extracted directly from the widget.data,
    // which is assumed to be populated from the database.
    // MODIFIED: Changed 'hallPrice' to 'eventPrice' to match database field name
    _hallPrice = (widget.data['eventPrice'] as num?)?.toDouble() ?? 0.0;
    print(
      'DEBUG: Initial hallPrice (eventPrice from DB) in Edit Page: $_hallPrice',
    ); // MODIFIED: Added for debugging

    // Initialize _selectedAddOns: first set all to false
    _selectedAddOns = {};
    _allPossibleAddOns.forEach((addonName, price) {
      _selectedAddOns[addonName] = false;
    });

    // Then, mark existing add-ons as true
    final dynamic existingAddOnsData = widget.data['addOns'];
    if (existingAddOnsData is List) {
      for (var existingAddOn in existingAddOnsData) {
        if (existingAddOn is String &&
            _selectedAddOns.containsKey(existingAddOn)) {
          _selectedAddOns[existingAddOn] = true;
        }
      }
    } else if (existingAddOnsData is Map<String, dynamic>) {
      // Handle old map format if necessary, assuming keys are add-on names
      existingAddOnsData.forEach((key, value) {
        if (_selectedAddOns.containsKey(key)) {
          _selectedAddOns[key] =
              true; // Assuming presence in map means it was selected
        }
      });
    }

    _visitorPaxController.addListener(_updateTotalPrice);
    _updateTotalPrice();
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _visitorPaxController.removeListener(_updateTotalPrice);
    _visitorPaxController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? _startDate!
          : _endDate!, // Use ! as we've null-checked in initState
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Optional: Adjust endDate if it is before startDate
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
        _updateTotalPrice();
      });
    }
  }

  void _updateTotalPrice() {
    // Ensure _startDate and _endDate are not null before proceeding
    if (_startDate == null || _endDate == null) {
      setState(() {
        _currentCalculatedTotalPrice = 0.0;
      });
      return;
    }

    int days = _endDate!.difference(_startDate!).inDays + 1;
    if (days < 1) days = 1;

    int persons = int.tryParse(_visitorPaxController.text) ?? 1;
    if (persons < 1) persons = 1;

    // Calculate total price including hall price extracted from the database (via widget.data)
    double packageCost = _hallPrice * days; // Hall price per day
    print(
      'DEBUG: packageCost (hall price * days): $packageCost',
    ); // MODIFIED: Added for debugging
    double perPersonCost =
        persons * 10.0; // Example per person cost (adjust as per your logic)

    // Calculate add-ons cost
    double addOnsCost = 0.0;
    _selectedAddOns.forEach((name, isSelected) {
      if (isSelected) {
        addOnsCost += _allPossibleAddOns[name] ?? 0.0;
      }
    });

    setState(() {
      _currentCalculatedTotalPrice = packageCost + perPersonCost + addOnsCost;
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Ensure dates are not null before calculating days
      if (_startDate == null || _endDate == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select both start and end dates.'),
            ),
          );
        }
        return;
      }

      int days = _endDate!.difference(_startDate!).inDays + 1;
      if (days < 1) days = 1;

      int pax = int.parse(_visitorPaxController.text.trim());

      // Prepare selected add-ons list for Firestore
      final List<String> addOnsToSave = _selectedAddOns.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      try {
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(widget.docId)
            .update({
              'eventName': _eventNameController.text
                  .trim(), // Kept for consistency, but now readOnly
              'visitorPax': pax,
              'startDate': Timestamp.fromDate(
                _startDate!,
              ), // Convert DateTime to Timestamp
              'endDate': Timestamp.fromDate(
                _endDate!,
              ), // Convert DateTime to Timestamp
              'days': days,
              'totalPrice': _currentCalculatedTotalPrice,
              'addOns': addOnsToSave, // Save the updated add-ons
              'status': 'Pending', // Set status back to Pending on edit
            });

        if (mounted) {
          // Show SnackBar BEFORE navigating
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking updated successfully')),
          );
          // Navigate back to MyBookingsPage
          context.go('/mybookings');
        }
      } catch (e) {
        print('Error updating booking: $e'); // Log the error for debugging
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update booking: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Booking')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Event Name (Non-editable)
              TextFormField(
                controller: _eventNameController,
                decoration: const InputDecoration(labelText: 'Event Name'),
                readOnly: true, // Make it non-editable
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Display the Hall Price
              Text(
                'Hall Price: RM ${_hallPrice.toStringAsFixed(2)} per day',
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              // Visitor Pax (Editable)
              TextFormField(
                controller: _visitorPaxController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Visitor Pax'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter number of guests';
                  }
                  if (int.tryParse(value) == null ||
                      (int.tryParse(value) ?? 0) <= 0) {
                    return 'Enter a valid positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Start Date (Editable)
              ListTile(
                title: Text(
                  'Start Date: ${(_startDate != null) ? DateFormat('yyyy-MM-dd').format(_startDate!) : 'Select Date'}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(true),
              ),
              // End Date (Editable)
              ListTile(
                title: Text(
                  'End Date: ${(_endDate != null) ? DateFormat('yyyy-MM-dd').format(_endDate!) : 'Select Date'}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(false),
              ),
              const SizedBox(height: 24),

              // Add-Ons Selection
              const Text(
                'Add-Ons:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._allPossibleAddOns.entries.map((entry) {
                final String addOnName = entry.key;
                final double addOnPrice = entry.value;
                return CheckboxListTile(
                  title: Text(
                    '$addOnName (RM ${addOnPrice.toStringAsFixed(2)})',
                  ),
                  value: _selectedAddOns[addOnName],
                  onChanged: (bool? newValue) {
                    setState(() {
                      _selectedAddOns[addOnName] = newValue!;
                      _updateTotalPrice(); // Recalculate total when add-ons change
                    });
                  },
                );
              }).toList(),
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
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
