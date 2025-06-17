import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../model/booking.dart'; // Import the Booking model

class MyBookingsList extends StatelessWidget {
  final List<Booking> bookings;

  const MyBookingsList({super.key, required this.bookings});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return const Center(
        child: Text(
          'You have no bookings yet.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking ID: ${booking.bookingId}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  booking.eventName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pax: ${booking.visitorPax} | Days: ${booking.days}',
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dates: ${DateFormat('MMM dd, yyyy').format(booking.startDate)} - ${DateFormat('MMM dd, yyyy').format(booking.endDate)}',
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total Price: RM${booking.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const SizedBox(height: 8),
                Text(
                  'Status: ${booking.status.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 14,
                    color: booking.status == 'confirmed' ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (booking.addOns.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Add-ons:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...booking.addOns.map((addon) => Text('• $addon')).toList(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
