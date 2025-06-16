import 'dart:async';
import 'package:flutter/material.dart';

class PreviewList extends StatefulWidget {
  const PreviewList({super.key});

  @override
  State<PreviewList> createState() => _PreviewListState();
}

class _PreviewListState extends State<PreviewList> {
  final List<String> images = [
    'assets/images/bhall.png',
    'assets/images/csuite.png',
    'assets/images/gballroom.png',
    'assets/images/ccenter.png',
    'assets/images/chall.png',
    'assets/images/communitycenter.png',
    'assets/images/park.png',
    'assets/images/rooftop.png',
    'assets/images/phall.png',
    'assets/images/stadium.png',
    'assets/images/phall.png',
  ];
  final ScrollController _controller = ScrollController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Optional: auto-scroll logic for ListView (not as smooth as PageView)
    // Remove if not needed
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_controller.hasClients) {
        double maxScroll = _controller.position.maxScrollExtent;
        double nextScroll = _controller.offset + 300;
        if (nextScroll > maxScroll) {
          nextScroll = 0;
        }
        _controller.animateTo(
          nextScroll,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = screenWidth;
    final itemHeight = screenWidth < 600 ? 160.0 : screenWidth * 0.25;

    return Center(
      child: Container(
        width: itemWidth,
        height: itemHeight,
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 31, 31, 31),
        ),
        child: ListView.builder(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          itemCount: images.length,
          itemBuilder: (context, index) {
            return Image.asset(
              images[index],
              fit: BoxFit.cover,
              width: itemWidth,
              height: itemHeight,
            );
          },
        ),
      ),
    );
  }
}
