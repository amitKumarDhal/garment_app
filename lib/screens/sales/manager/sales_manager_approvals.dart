// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/constants/colors.dart';
import '../../../controllers/sales/sales_manager_controller.dart';
import '../../../data/models/order_model.dart';
import 'order_approval_screen.dart';

// ✅ OPTIMIZED: Converted to StatefulWidget to prevent memory leaks from Get.put
class SalesManagerApprovals extends StatefulWidget {
  const SalesManagerApprovals({super.key});

  @override
  State<SalesManagerApprovals> createState() => _SalesManagerApprovalsState();
}

class _SalesManagerApprovalsState extends State<SalesManagerApprovals> {
  late final SalesManagerController controller;

  @override
  void initState() {
    super.initState();
    // ✅ Safe: Only initializes once when the screen is loaded
    controller = Get.put(SalesManagerController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchPendingOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatCurrency = NumberFormat('#,##,##0', 'en_IN');

    return DefaultTabController(
      length: 2, // ✅ Added Tab Controller
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),

        // ✅ PREMIUM APP BAR WITH TABS
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
          elevation: 0,
          centerTitle: false,
          titleSpacing: 20,
          systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          title: Text(
            "Action Required",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
          bottom: TabBar(
            indicatorColor: TColors.primary,
            indicatorWeight: 3,
            labelColor: TColors.primary,
            unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            tabs: const [
              Tab(text: "New Orders"),
              Tab(text: "Payments & Dues"),
            ],
          ),
        ),

        body: TabBarView(
          children: [
            // ==========================================
            // TAB 1: NEW ORDERS (Pending Orders Only)
            // ==========================================
            RefreshIndicator(
              color: TColors.primary,
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              onRefresh: () async => controller.fetchPendingOrders(),
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator(color: TColors.primary));
                }

                final pendingOrders = controller.pendingOrders.toList();

                if (pendingOrders.isEmpty) {
                  return _buildEmptyState(
                      isDark,
                      "No New Orders",
                      "There are no pending orders\nwaiting for your verification."
                  );
                }

                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: pendingOrders.length,
                  itemBuilder: (context, index) {
                    final order = pendingOrders[index];
                    return _buildPremiumApprovalCard(context, order, isDark, formatCurrency);
                  },
                );
              }),
            ),

            // ==========================================
            // TAB 2: PAYMENTS & DUES (Payment Requests)
            // ==========================================
            RefreshIndicator(
              color: TColors.primary,
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              onRefresh: () async => controller.fetchPendingOrders(), // Dummy refresh to maintain UX feel
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('payment_requests')
                    .where('status', isEqualTo: 'pending')
                    .snapshots(),
                builder: (context, paymentSnap) {
                  if (!paymentSnap.hasData && paymentSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: TColors.primary));
                  }

                  final paymentDocs = paymentSnap.data?.docs ?? [];

                  if (paymentDocs.isEmpty) {
                    return _buildEmptyState(
                        isDark,
                        "All Dues Settled",
                        "There are no payment requests\nwaiting for your approval."
                    );
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: paymentDocs.length,
                    itemBuilder: (context, index) {
                      return _buildPremiumPaymentCard(context, paymentDocs[index], isDark, formatCurrency);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ PREMIUM PAYMENT REQUEST CARD
  Widget _buildPremiumPaymentCard(BuildContext context, QueryDocumentSnapshot doc, bool isDark, NumberFormat formatCurrency) {
    final data = doc.data() as Map<String, dynamic>;
    final amount = data['amount'] ?? 0.0;
    final agent = data['agentName'] ?? 'Associate';
    final orderNo = data['manualOrderNo'] ?? 'Unknown';
    final orderId = data['orderId'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.5), // Highlighted border for payments
          width: 1.5,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            HapticFeedback.lightImpact();
            Get.dialog(const Center(child: CircularProgressIndicator(color: TColors.primary)), barrierDismissible: false);
            try {
              final orderDoc = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
              Get.back(); // close loading
              if (orderDoc.exists) {
                Get.to(() => OrderApprovalScreen(order: OrderModel.fromSnapshot(orderDoc)));
              } else {
                Get.snackbar("Error", "Order not found.", backgroundColor: Colors.redAccent.withValues(alpha:0.1), colorText: Colors.red);
              }
            } catch(e) {
              Get.back();
              Get.snackbar("Error", "Failed to load order.", backgroundColor: Colors.redAccent.withValues(alpha:0.1), colorText: Colors.red);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Type & Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        "Payment Request",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.orange.shade700,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "ACTION REQ",
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Middle Row: Order Info & Agent
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 18,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Order #$orderNo",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Collected by $agent",
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),

                // Bottom Row: Amount & Action Arrow
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Approval Amount",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                          ),
                        ),
                        Text(
                          "₹${formatCurrency.format(amount)}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Text(
                            "Verify",
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.orange),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ COMPACT PREMIUM ORDER CARD
  Widget _buildPremiumApprovalCard(BuildContext context, OrderModel order, bool isDark, NumberFormat formatCurrency) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
          width: 1.5,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Get.to(() => OrderApprovalScreen(order: order)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Client Name & Pending Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        order.clientName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "PENDING",
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Middle Row: Product Info & Associate Name
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        size: 18,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${order.quantity}x ${order.productName}",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "By ${order.marketingPersonName}",
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),

                // Bottom Row: Price & Action Arrow
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total Amount",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                          ),
                        ),
                        Text(
                          "₹${formatCurrency.format(order.totalAmount)}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: TColors.cyberYellow.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Text(
                            "Review",
                            style: TextStyle(
                              color: TColors.cyberYellow,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 12, color: TColors.cyberYellow),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ PREMIUM DYNAMIC EMPTY STATE
  Widget _buildEmptyState(bool isDark, String title, String subtitle) {
    return Stack(
      children: [
        ListView(), // Enables pull-to-refresh even when empty
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.task_alt_rounded,
                  size: 64,
                  color: isDark ? Colors.white30 : Colors.black26,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.black54,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}