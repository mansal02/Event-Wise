import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class PaymentPage extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;

  const PaymentPage({
    super.key,
    required this.bookingId,
    required this.bookingData,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isLoading = false;

  Future<void> _updateBookingStatus(String newStatus) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({'status': newStatus});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking status updated to $newStatus!')),
        );
        // Navigate back to bookings or a confirmation page
        context.go('/mybookings');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.bookingData;
    final bookingDate = (booking['bookingDate'] as Timestamp?)?.toDate();
    final startDate = (booking['startDate'] as Timestamp?)?.toDate();
    final endDate = (booking['endDate'] as Timestamp?)?.toDate();

    final dynamic addOnsData = booking['addOns'];
    List<String> displayedAddOns = [];

    if (addOnsData is List) {
      displayedAddOns = List<String>.from(addOnsData);
    } else if (addOnsData is Map<String, dynamic>) {
      displayedAddOns = addOnsData.entries
          .map((entry) => '${entry.key}: RM ${entry.value}')
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Confirm Your Booking Payment',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const Divider(height: 30, thickness: 1),
                      _buildDetailRow(
                          'Event Name:', booking['eventName'] ?? 'N/A'),
                      _buildDetailRow(
                          'Start Date:',
                          startDate != null
                              ? DateFormat('yyyy-MM-dd').format(startDate)
                              : 'N/A'),
                      _buildDetailRow(
                          'End Date:',
                          endDate != null
                              ? DateFormat('yyyy-MM-dd').format(endDate)
                              : 'N/A'),
                      _buildDetailRow('Days:', booking['days']?.toString() ?? 'N/A'),
                      _buildDetailRow('Visitor Pax:',
                          booking['visitorPax']?.toString() ?? 'N/A'),
                      _buildDetailRow(
                          'Booked On:',
                          bookingDate != null
                              ? DateFormat('yyyy-MM-dd HH:mm')
                                  .format(bookingDate)
                              : 'N/A'),
                      if (displayedAddOns.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        const Text(
                          'Selected Add-Ons:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ...displayedAddOns
                            .map((item) => Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text('- $item'),
                                ))
                            .toList(),
                      ],
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Total Amount: RM ${booking['totalPrice'] ?? 'N/A'}',
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            // In a real app, you would initiate payment gateway here
                            // On successful payment, update status to 'Paid'
                            _updateBookingStatus('Paid');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 15),
                            textStyle: const TextStyle(fontSize: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          child: const Text('Proceed to Payment'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
