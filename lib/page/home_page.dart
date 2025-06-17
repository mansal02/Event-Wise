import 'package:flutter/material.dart';

import '../component/header.dart';
import '../component/preview_list.dart';
import '../component/event_hall_preview.dart';
import '../details/event_hall_packages.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Header(size: size),
            PreviewList(),
            EventHallPreview(
              eventHallPackages: eventHallPackages,
              size: size,
            ),
          ],
        ),
      ),
    );
  }
}