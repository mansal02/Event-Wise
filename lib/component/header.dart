import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class Header extends StatelessWidget {
  final Size? size;

  const Header({super.key, this.size});

  @override
  Widget build(BuildContext context) {
    final screenSize = size ?? MediaQuery.of(context).size;
    final headerHeight = screenSize.height * 0.18; // Reduced height

    // Remove any logic or widget that would make this header "sticky" (fixed position).
    // Just return the header as a normal widget in the widget tree.

    return Container(
      width: screenSize.width,
      height: headerHeight,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color.fromARGB(255, 87, 133, 154), Color(0xFF574977)],
          stops: [0.3, 1],
          begin: AlignmentDirectional(-0.34, 1),
          end: AlignmentDirectional(0.34, -1),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenSize.width * 0.05,
          vertical: headerHeight * 0.10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Search and Auth button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.search, color: Colors.white, size: 22),
                    SizedBox(width: screenSize.width * 0.02),
                    Text(
                      'Search',
                      style: GoogleFonts.lato(
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                        fontSize: screenSize.width * 0.042,
                      ),
                    ),
                  ],
                ),
                
              ],
            ),
            SizedBox(height: headerHeight * 0.10),
            Text(
              'Welcome to Event Wise',
              style: GoogleFonts.lato(
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontSize: screenSize.width * 0.052,
              ),
            ),
            SizedBox(height: headerHeight * 0.03),
            Text(
              'What are you looking for?',
              style: GoogleFonts.lato(
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.9),
                fontSize: screenSize.width * 0.045,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
