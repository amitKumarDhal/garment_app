import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // --- GRADIENT HELPERS ---
  LinearGradient _buildFadedGradient(Color color, bool isDark) {
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        color.withValues(alpha: isDark ? 0.2 : 0.15),
        color.withValues(alpha: isDark ? 0.05 : 0.05),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Order Management", style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : TColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          unselectedLabelColor: Colors.white70,
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text("No orders found", style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        Color statusColor = _getStatusColorForManager(order.status);

        DateTime deadline = DateTime(order.deliveryDate.year, order.deliveryDate.month, order.deliveryDate.day);
        int daysLeft = deadline.difference(today).inDays;

        bool isOverdue = daysLeft < 0;
        bool isDueToday = daysLeft == 0;
        bool isDone = ['delivered', 'completed', 'shipped'].contains(order.status.toLowerCase());

        Color urgencyColor = isDone ? Colors.green : (isOverdue ? Colors.redAccent : (isDueToday ? Colors.orange : Colors.grey.shade600));

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
            boxShadow: [
              if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 5))
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HEADER: ID & STATUS ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            order.manualOrderNo ?? "ID: ${order.id?.substring(0,6)}",
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                  gradient: _buildFadedGradient(statusColor, isDark),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: statusColor.withValues(alpha: 0.3))
                              ),
                              child: Text(order.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900)),
                            ),
                            if (order.updatedAt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                "Updated ${DateFormat('dd MMM, hh:mm a').format(order.updatedAt!)}\nby ${order.lastUpdatedBy ?? 'System'}",
                                textAlign: TextAlign.right,
                                style: TextStyle(fontSize: 8.5, color: Colors.grey.shade500, fontStyle: FontStyle.italic, height: 1.2),
                              ),
                            ]
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // --- INFO ROWS ---
                    _buildInfoRow(Icons.business_rounded, "Client", order.clientName, isDark),
                    const SizedBox(height: 6),
                    _buildInfoRow(Icons.category_outlined, "Product", order.productName, isDark),
                    const SizedBox(height: 6),
                    _buildInfoRow(Icons.layers_outlined, "Quantity", "${order.quantity} Units", isDark),
                    const SizedBox(height: 16),

                    // --- ACTION BUTTONS ---
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Get.to(() => OrderApprovalScreen(order: order)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: TColors.primary.withValues(alpha: 0.5)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("VIEW DETAILS", style: TextStyle(color: TColors.primary, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // ✅ HISTORY BUTTON
                        Container(
                          height: 46,
                          width: 46,
                          decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade300)
                          ),
                          child: IconButton(
                            icon: Icon(Icons.history_rounded, color: isDark ? Colors.white : Colors.black87, size: 20),
                            onPressed: () => _showHistoryDialog(context, order, isDark),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // --- FOOTER: DEADLINE ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: _buildFadedGradient(urgencyColor, isDark),
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 14, color: urgencyColor),
                    const SizedBox(width: 8),
                    Text("Target: ${DateFormat('dd MMM yyyy').format(deadline)}", style: TextStyle(color: urgencyColor, fontSize: 11, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text(isDone ? "COMPLETED" : (isOverdue ? "OVERDUE" : (isDueToday ? "DUE TODAY" : "ON TRACK")), style: TextStyle(color: urgencyColor, fontSize: 10, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Text("$label: ", style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
        Expanded(child: Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 12, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  // --- HISTORY TIMELINE BOTTOM SHEET ---
  void _showHistoryDialog(BuildContext context, OrderModel order, bool isDark) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) {
          // Reverse history so newest is at the top
          List<dynamic> history = List.from(order.stageHistory.reversed);

          return FractionallySizedBox(
            heightFactor: 0.6,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Stage History", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: TColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(order.manualOrderNo ?? "Unknown ID", style: const TextStyle(color: TColors.primary, fontWeight: FontWeight.w900, fontSize: 12)),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (history.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text("No updates have been made yet.", style: TextStyle(color: Colors.grey.shade500)),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          var event = history[index];

                          DateTime time = DateTime.now();
                          if (event['timestamp'] != null) {
                            time = (event['timestamp'] as Timestamp).toDate();
                          }

                          String stage = event['stage'] ?? 'Unknown Stage';
                          String updater = event['updatedBy'] ?? 'System';
                          Color color = _getStatusColorForManager(stage);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    Container(
                                      width: 14, height: 14,
                                      decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: 0.3), width: 3)),
                                    ),
                                    if (index != history.length - 1)
                                      Container(width: 2, height: 40, color: isDark ? Colors.white10 : Colors.grey.shade200)
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(stage, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.person_rounded, size: 12, color: Colors.grey.shade500),
                                          const SizedBox(width: 4),
                                          Text("Updated by $updater", style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                                Text(
                                    DateFormat('dd MMM\nhh:mm a').format(time),
                                    textAlign: TextAlign.right,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, height: 1.3)
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    )
                ],
              ),
            ),
          );
        }
    );
  }

  Color _getStatusColorForManager(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Colors.blue;
      case 'rejected': return Colors.red;
      case 'cutting': return Colors.orange;
      case 'printing': return Colors.indigo;
      case 'printed': return Colors.cyan;
      case 'stitching': return Colors.amber;
      case 'stitched': return Colors.brown;
      case 'packing': return Colors.purple;
      case 'packed': return Colors.deepPurple;
      case 'shipping':
      case 'shipped': return Colors.teal;
      case 'delivered': return Colors.green;
      case 'completed': return Colors.green;
      default: return Colors.grey;
    }
  }
}