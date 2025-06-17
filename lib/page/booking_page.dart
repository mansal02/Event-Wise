import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:event_wise_2/component/header.dart';

class BookingPage extends StatelessWidget {
  const BookingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Header(),
          // Rest of your booking page content
        ],
      ),
    );
  }
}
