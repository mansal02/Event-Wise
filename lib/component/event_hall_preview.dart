import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart'; 
import '../details/event_hall_package.dart'; 

class EventHallPreview extends StatelessWidget {
  final List<EventHallPackage> eventHallPackages;
  final Size size;

  const EventHallPreview({
    super.key,
    required this.eventHallPackages,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final gridCrossAxisCount = 1; 

    final displayCount = eventHallPackages.length.clamp(0, 4); 

    if (displayCount == 0) {
      return const SizedBox.shrink(); 
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured Event Halls', 
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.bold, 
                  fontSize: size.width * 0.045,
                  color: Colors.black,
                ),
              ),
              TextButton(
                onPressed: () {
                  context.go('/event-hall'); 
                },
                child: Text(
                  'See All',
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.w500, 
                    fontSize: size.width * 0.035,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: size.width * 0.025),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(), 
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridCrossAxisCount,
              childAspectRatio: size.width / (size.height * 0.28), 
              crossAxisSpacing: size.width * 0.04,
              mainAxisSpacing: size.width * 0.04,
            ),
            itemCount: displayCount, 
            itemBuilder: (context, index) {
              final package = eventHallPackages[index];
              return InkWell(
                onTap: () {                  
                  context.push('/booking', extra: package);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha((0.15 * 255).round()),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.blue.withAlpha((0.12 * 255).round()),
                      width: 1.2,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(size.width * 0.03),
                    child: Row(
                      children: [
                        Flexible(
                          flex: 3,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              package.image, 
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(width: size.width * 0.02),
                        Expanded(
                          flex: 5,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    package.title, 
                                    style: GoogleFonts.lato(
                                      fontWeight: FontWeight.bold,
                                      fontSize: size.width * 0.037,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: size.height * 0.007),
                                  Text(
                                    package.description, 
                                    style: GoogleFonts.lato(
                                      fontWeight: FontWeight.normal,
                                      fontSize: size.width * 0.029,
                                      color: Colors.grey[700],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Price: RM${package.price.toStringAsFixed(2)}/day',
                                    style: GoogleFonts.lato(
                                      fontWeight: FontWeight.bold,
                                      fontSize: size.width * 0.032,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: SizedBox(
                                      height: 28,
                                      width: constraints.maxWidth < 100 ? constraints.maxWidth : 90,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          context.push('/booking', extra: package);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color.fromARGB(255, 192, 107, 241),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                                          textStyle: GoogleFonts.lato(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text('Book Now'),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}