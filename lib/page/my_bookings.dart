import 'package:cloud_firestore/cloud_firestore.dart'; // Required for QuerySnapshot
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../component/my_bookings_list.dart';
import '../model/booking.dart';
import '../service/database.dart';

class MyBookingsPage extends StatelessWidget {
  const MyBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Bookings'),
        ),
        body: const Center(
          child: Text('Please log in to view your bookings.'),
        ),
      );
    }

    final DatabaseService databaseService = DatabaseService();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Bookings',
          style: GoogleFonts.lato(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white, // Assuming your AppBar has a background
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor, // Use theme primary color
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: databaseService.getUserBookings(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No bookings found.'));
          }

          // Map the raw Firestore documents to your Booking model
          final bookings = snapshot.data!.docs.map((doc) => Booking.fromFirestore(doc)).toList();

          return MyBookingsList(bookings: bookings);
        },
      ),
    );
  }
}
