import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yoobbel/controllers/sales/sales_manager_controller.dart';
import '../../../data/models/order_model.dart';
import '../../../utils/constants/colors.dart';
import 'order_approval_screen.dart'; // Import your details screen

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> with SingleTickerProviderStateMixin {
  final controller = Get.put(SalesManagerController());
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    controller.fetchOrderHistory(); // ✅ Load data
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Order Management", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: TColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "🔥 In Production"),
            Tab(text: "✅ Completed"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Active
          Obx(() => _buildOrderList(controller.activeOrders, isDark)),
          // Tab 2: Completed
          Obx(() => _buildOrderList(controller.completedOrders, isDark)),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<OrderModel> orders, bool isDark) {
    if (orders.isEmpty) {
      return const Center(child: Text("No orders found", style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(
              "#${order.manualOrderNo ?? '---'}  •  ${order.clientName}",
              style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
            ),
            subtitle: Text(
              "Status: ${order.status}",
              style: TextStyle(color: TColors.primary, fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Get.to(() => OrderApprovalScreen(order: order)),
          ),
        );
      },
    );
  }
}