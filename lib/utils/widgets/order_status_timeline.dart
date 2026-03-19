import 'package:flutter/material.dart';

class OrderStatusTimeline extends StatelessWidget {
  final String currentStatus;

  const OrderStatusTimeline({super.key, required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    // ✅ UPDATED: The full 15-step timeline (Placed + 14 Production Stages)
    final steps = [
      'Placed',
      'Approved',
      'Fab Purchased',
      'Fab Ready',
      'Cutting',
      'Cutting Done',
      'Printing',
      'Printed',
      'Stitching',
      'Stitched',
      'Packing',
      'Packed',
      'Shipping',
      'Shipped',
      'Delivered'
    ];

    // Find index of current status
    int currentIndex = steps.indexWhere((s) => s.toLowerCase() == currentStatus.toLowerCase());

    // Treat 'Pending' the same as 'Placed' for the timeline UI
    if (currentStatus.toLowerCase() == 'pending') {
      currentIndex = 0;
    }

    if (currentIndex == -1) currentIndex = 0; // Default start

    // Handle "Rejected" case specifically
    if (currentStatus.toLowerCase() == 'rejected') {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red),
          ),
          child: const Text(
            "ORDER REJECTED",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Horizontal Scrollable Timeline
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(), // Adds a smooth scrolling effect
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start, // Aligns elements to the top
            children: List.generate(steps.length, (index) {
              bool isCompleted = index <= currentIndex;
              bool isLast = index == steps.length - 1;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The Step Dot & Label
                  Column(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted ? Colors.green : Colors.grey[300],
                          border: Border.all(
                            color: isCompleted ? Colors.green : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : Text(
                            "${index + 1}",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        steps[index],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                          color: isCompleted ? Colors.green[800] : Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  // The Line Connector
                  if (!isLast)
                    Container(
                      width: 40,
                      height: 4,
                      // ✅ Perfectly aligns the line with the center of the 30x30 circle
                      margin: const EdgeInsets.only(top: 13, left: 4, right: 4),
                      color: index < currentIndex ? Colors.green : Colors.grey[300],
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}