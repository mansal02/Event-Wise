import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Header extends StatefulWidget {
  final Size? size;
  final ValueChanged<String> onSearchChanged;

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
    _searchController.addListener(() {
      widget.onSearchChanged(_searchController.text);
    });
  }

  @override
  void dispose() {
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
          colors: [
            Colors.black,
            Color(0xFFB8860B),
          ],
          stops: [0.0, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
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
                Expanded(
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
                                widget.onSearchChanged('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                    ),
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      fontSize: screenSize.width * 0.042,
                    ),
                    cursorColor: Colors.white,
                  ),
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