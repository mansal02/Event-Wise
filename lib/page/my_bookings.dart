import package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../component/my_bookings_list.dart';
import '../service/database.dart';
import '../model/booking.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';                                                

class MyBookingsPage extends StatelessWidget {
  const MyBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('My Bookings'),
        ),
        body: Center(
          child: Text('Please log in to view your bookings.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My Bookings'),
      ),
      body: StreamBuilder<QuerySnapshot<Booking>>(
        stream: DatabaseService().getUserBookings(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final bookings = snapshot.data?.docs.map((doc) => doc.data()).toList() ?? [];
          return MyBookingsList(bookings: bookings);
        },
      ),
    );
  }
}