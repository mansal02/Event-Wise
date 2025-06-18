import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Header extends StatefulWidget {
  final Size? size;
  final ValueChanged<String> onSearchChanged; // Callback for search input changes

  const Header({super.key, this.size, required this.onSearchChanged});

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // Add a listener to the text controller to trigger the callback
    _searchController.addListener(() {
      widget.onSearchChanged(_searchController.text);
    });
  }

  @override
  void dispose() {
    // Remove the listener to prevent memory leaks
    _searchController.removeListener(() {
      widget.onSearchChanged(_searchController.text);
    });
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = widget.size ?? MediaQuery.of(context).size;
    final headerHeight = screenSize.height * 0.18;

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded( // Use Expanded so TextField takes available space
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search packages...',
                      hintStyle: GoogleFonts.lato(
                        fontWeight: FontWeight.w300,
                        color: Colors.white.withOpacity(0.7),
                        fontSize: screenSize.width * 0.042,
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.white, size: 22),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.white),
                              onPressed: () {
                                _searchController.clear();
                                // Manually trigger search change after clearing
                                widget.onSearchChanged('');
                              },
                            )
                          : null,
                      border: InputBorder.none, // Remove default border for cleaner look
                      contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                    ),
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      fontSize: screenSize.width * 0.042,
                    ),
                    cursorColor: Colors.white, // White cursor for visibility on dark background
                  ),
                ),
                // If you had an auth button here previously, it should be re-added.
                // Based on previous files, it seemed handled by AppBar/Drawer.
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
