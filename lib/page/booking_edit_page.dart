import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    _eventNameController = TextEditingController(
      text: widget.data['eventName'],
    );
    _visitorPaxController = TextEditingController(
      text: widget.data['visitorPax'].toString(),
    );
    _startDate = (widget.data['startDate'] as Timestamp).toDate();
    _endDate = (widget.data['endDate'] as Timestamp).toDate();
    _hallPrice = widget.data['hallPrice'] ?? 0.0; // Get hall price from data

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
      initialDate: isStart ? _startDate! : _endDate!,
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

    // Calculate total price including hall price
    double packageCost = _hallPrice * days; // Hall price per day
    double perPersonCost = persons * 10.0; // Example per person cost

    setState(() {
      _currentCalculatedTotalPrice = packageCost + perPersonCost;
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      int days = _endDate!.difference(_startDate!).inDays + 1;
      if (days < 1) days = 1;

      int pax = int.parse(_visitorPaxController.text.trim());

      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.docId)
          .update({
            'eventName': _eventNameController.text.trim(),
            'visitorPax': pax,
            'startDate': _startDate,
            'endDate': _endDate,
            'days': days,
            'totalPrice': _currentCalculatedTotalPrice,
            'status': 'Pending',
          });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking updated successfully')),
        );
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
              TextFormField(
                controller: _eventNameController,
                decoration: const InputDecoration(labelText: 'Event Name'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter event name'
                    : null,
              ),
              const SizedBox(height: 16),
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
              ListTile(
                title: Text(
                  'Start Date: ${DateFormat('yyyy-MM-dd').format(_startDate!)}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(true),
              ),
              ListTile(
                title: Text(
                  'End Date: ${DateFormat('yyyy-MM-dd').format(_endDate!)}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(false),
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
