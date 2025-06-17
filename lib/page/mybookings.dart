import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Bookings')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Please log in to view your bookings.'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.go('/sign-in'),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: _currentUser!.uid)
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
            return const Center(child: Text('No bookings found.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final booking =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;
              final bookingDate = (booking['bookingDate'] as Timestamp?)
                  ?.toDate();
              final startDate = (booking['startDate'] as Timestamp?)?.toDate();
              final endDate = (booking['endDate'] as Timestamp?)?.toDate();

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking['eventName'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start Date: ${startDate != null ? DateFormat('yyyy-MM-dd').format(startDate) : 'N/A'}',
                      ),
                      Text(
                        'End Date: ${endDate != null ? DateFormat('yyyy-MM-dd').format(endDate) : 'N/A'}',
                      ),
                      Text('Days: ${booking['days'] ?? 'N/A'}'),
                      Text('Visitor Pax: ${booking['visitorPax'] ?? 'N/A'}'),
                      Text('Status: ${booking['status'] ?? 'N/A'}'),
                      Text('Total Price: RM ${booking['totalPrice'] ?? 'N/A'}'),
                      Text(
                        'Booked On: ${bookingDate != null ? DateFormat('yyyy-MM-dd HH:mm').format(bookingDate) : 'N/A'}',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}