import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../component/event_hall_list.dart';
import '../details/event_hall_packages.dart'; 
import '../details/event_hall_package.dart'; 

class EventHallPage extends StatelessWidget {
  const EventHallPage({super.key, required this.eventHallPackages, required int headerMaxExtent});

  final List<EventHallPackage> eventHallPackages; 

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Event Hall',
                    style: GoogleFonts.lato(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                  Text(
                    'Book your event hall now!',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: const Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  EventHallList(
                    eventHallPackages: eventHallPackages, 
                    size: size,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}