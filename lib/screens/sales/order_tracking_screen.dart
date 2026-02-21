import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/sales/order_tracking_controller.dart';
import '../../utils/widgets/order_status_timeline.dart'; // ✅ Correct Path
import '../../utils/constants/colors.dart';

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OrderTrackingController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: const Text("Track Order"),
        backgroundColor: TColors.primary, // Make sure TColors.primary is defined in colors.dart
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- SEARCH BAR ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: controller.searchController,
                decoration: InputDecoration(
                  hintText: "Enter Order ID or Client Name",
                  border: InputBorder.none,
                  icon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () => controller.clearSearch(),
                  ),
                ),
                onSubmitted: (val) => controller.searchOrder(val),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // --- SEARCH BUTTON ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => controller.searchOrder(controller.searchController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Track Now", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),

            const SizedBox(height: 24),

            // --- RESULTS AREA ---
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!controller.hasSearched.value) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_searching, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text("Enter details to track an order", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                if (controller.searchResults.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text("No order found with that ID or Name.", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                // Show Results List
                return ListView.builder(
                  itemCount: controller.searchResults.length,
                  itemBuilder: (context, index) {
                    final order = controller.searchResults[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: Order ID + Status Badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  order.manualOrderNo ?? "ID: ${order.id?.substring(0, 6)}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: TColors.primary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(order.status).withValues(alpha:0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    order.status,
                                    style: TextStyle(
                                      color: _getStatusColor(order.status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 8),
                            Text("Client: ${order.clientName}", style: const TextStyle(fontWeight: FontWeight.w500)),
                            Text("Product: ${order.productName} (${order.quantity} pcs)", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                            Text("Date: ${DateFormat('dd MMM yyyy').format(order.orderDate)}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),

                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 10),

                            // ✅ THE TIMELINE WIDGET
                            const Text("Live Status:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 10),
                            // Using the widget we just created
                            OrderStatusTimeline(currentStatus: order.status),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      case 'placed': return Colors.orange;
      case 'delivered': return Colors.blue;
      default: return Colors.purple;
    }
  }
}