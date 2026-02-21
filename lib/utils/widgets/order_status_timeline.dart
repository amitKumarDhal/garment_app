import 'package:flutter/material.dart';
// If you use TColors, import it here: import '../constants/colors.dart';

class OrderStatusTimeline extends StatelessWidget {
  final String currentStatus;

  const OrderStatusTimeline({super.key, required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    // Define the standard workflow steps
    final steps = [
      'Placed',
      'Approved',
      'Cutting',
      'Stitching',
      'Printing',
      'Packing',
      'Shipping',
      'Delivered'
    ];

    // Find index of current status (default to 0 if not found)
    int currentIndex = steps.indexWhere((s) => s.toLowerCase() == currentStatus.toLowerCase());
    if (currentIndex == -1) currentIndex = 0; // Default start

    // Handle "Rejected" case specifically
    if (currentStatus.toLowerCase() == 'rejected') {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha:0.1),
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
          child: Row(
            children: List.generate(steps.length, (index) {
              bool isCompleted = index <= currentIndex;
              bool isLast = index == steps.length - 1;

              return Row(
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
                      margin: const EdgeInsets.only(bottom: 20, left: 4, right: 4),
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