import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/production/unit_supervisor_controller.dart';
import '../../utils/constants/colors.dart';
import '../../data/models/order_model.dart';

class UnitSupervisorOrdersScreen extends StatelessWidget {
  const UnitSupervisorOrdersScreen({super.key});

  // --- GRADIENT HELPERS ---
  LinearGradient _buildSolidGradient(Color color) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [color.withValues(alpha: 0.6), color],
    );
  }

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
    final controller = Get.put(UnitSupervisorController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<String> displayStages = ['All', ...controller.factoryStages];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
        elevation: 0,
        centerTitle: false,
        titleSpacing: 24,
        automaticallyImplyLeading: false,
        title: Text(
          "Stage Explorer",
          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5),
        ),
      ),
      body: Column(
        children: [
          // --- 1. SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: TextField(
                onChanged: (value) => controller.updateSearchQuery(value),
                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Search by Order ID, Client, or Product...",
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: TColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
          ),

          // --- 2. HORIZONTAL STAGE SELECTOR (WITH FLOATING BADGES) ---
          Container(
            height: 60, // Increased slightly to make room for the badge
            margin: const EdgeInsets.only(bottom: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: displayStages.length,
              itemBuilder: (context, index) {
                String stage = displayStages[index];

                return Obx(() {
                  bool isSelected = controller.selectedFilterStage.value == stage;
                  Color baseColor = stage == 'All' ? TColors.primary : _getStatusColor(stage);

                  // ✅ CALCULATE COUNT FOR THIS SPECIFIC STAGE
                  int count = stage == 'All'
                      ? controller.activeOrders.length
                      : controller.activeOrders.where((o) => o.status.toLowerCase() == stage.toLowerCase()).length;

                  return Padding(
                    padding: const EdgeInsets.only(right: 14, top: 8), // Padding creates space for the badge
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // The Main Stage Pill
                        GestureDetector(
                          onTap: () => controller.setFilterStage(stage),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: isSelected ? _buildSolidGradient(baseColor) : null,
                              color: isSelected ? null : (isDark ? Colors.white10 : Colors.white),
                              borderRadius: BorderRadius.circular(20),
                              border: isSelected ? null : Border.all(color: isDark ? Colors.transparent : Colors.grey.shade300),
                              boxShadow: [
                                if (isSelected && !isDark)
                                  BoxShadow(color: baseColor.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4))
                              ],
                            ),
                            child: Center(
                              child: Text(
                                stage,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.black87),
                                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // ✅ THE FLOATING NUMBER BADGE
                        if (count > 0) // Only show the badge if there are orders
                          Positioned(
                            top: -6,
                            right: -6,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : baseColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
                                      width: 2
                                  ),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))
                                  ]
                              ),
                              child: Text(
                                count.toString(),
                                style: TextStyle(
                                  color: isSelected ? baseColor : Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                });
              },
            ),
          ),

          // --- 3. FILTERED ORDER LIST ---
          Expanded(
            child: Obx(() {
              if (controller.filteredOrders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 60, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text("No matches found", style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }

              // Create a local copy for sorting
              var sortedOrders = List<OrderModel>.from(controller.filteredOrders);

              if (controller.selectedFilterStage.value == 'All') {
                sortedOrders.sort((a, b) {
                  String valA = a.manualOrderNo ?? a.id ?? "";
                  String valB = b.manualOrderNo ?? b.id ?? "";
                  return valB.compareTo(valA);
                });
              } else {
                sortedOrders.sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));
              }

              DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 100),
                itemCount: sortedOrders.length,
                itemBuilder: (context, index) {
                  var order = sortedOrders[index];
                  Color statusColor = _getStatusColor(order.status);
                  DateTime deadline = DateTime(order.deliveryDate.year, order.deliveryDate.month, order.deliveryDate.day);
                  int daysLeft = deadline.difference(today).inDays;

                  bool isOverdue = daysLeft < 0;
                  bool isDueToday = daysLeft == 0;
                  bool isDone = ['delivered', 'completed'].contains(order.status.toLowerCase());

                  Color urgencyColor = isDone ? Colors.green : (isOverdue ? Colors.redAccent : (isDueToday ? Colors.orange : Colors.grey.shade600));

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
                      boxShadow: [
                        if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Highlight the Order Number
                                  Text(
                                      order.manualOrderNo ?? "ID: ${order.id?.substring(0,6)}",
                                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : Colors.black87)
                                  ),
                                  // Gradient Status Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                        gradient: _buildFadedGradient(statusColor, isDark),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: statusColor.withValues(alpha: 0.3))
                                    ),
                                    child: Text(order.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(isDark, Icons.business_rounded, "Client", order.clientName),
                              const SizedBox(height: 6),
                              _buildInfoRow(isDark, Icons.category_outlined, "Product", order.productName),
                              const SizedBox(height: 6),
                              _buildInfoRow(isDark, Icons.layers_outlined, "Quantity", "${order.quantity} Units"),
                              const SizedBox(height: 16),

                              // MODERN GRADIENT ACTION BUTTON
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: _buildSolidGradient(TColors.primary),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(color: TColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => _showUpdateStageDialog(context, order, controller, isDark),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.edit_road_rounded, size: 16, color: Colors.white),
                                          const SizedBox(width: 8),
                                          const Text("UPDATE STAGE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // FADED GRADIENT FOOTER
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
                              Text(isOverdue ? "OVERDUE" : (isDueToday ? "DUE TODAY" : "ON TRACK"), style: TextStyle(color: urgencyColor, fontSize: 10, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(bool isDark, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Text("$label: ", style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
        Expanded(child: Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 12, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  void _showUpdateStageDialog(BuildContext context, OrderModel order, UnitSupervisorController controller, bool isDark) {
    showModalBottomSheet(
        context: context,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Update Order: ${order.manualOrderNo}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 4),
                Text("Current Stage: ${order.status}", style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: controller.factoryStages.map((stage) {
                    bool isCurrent = stage.toLowerCase() == order.status.toLowerCase();
                    Color baseColor = _getStatusColor(stage);

                    return GestureDetector(
                      onTap: isCurrent ? null : () {
                        Get.back();
                        controller.updateProductionStage(order.id!, order.status, stage);
                      },
                      child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                              gradient: isCurrent ? _buildSolidGradient(TColors.primary) : null,
                              color: isCurrent ? null : (isDark ? Colors.white10 : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(8),
                              border: isCurrent ? null : Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300)
                          ),
                          child: Text(
                              stage,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isCurrent ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.black87)
                              )
                          )
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Colors.blue;
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
      default: return Colors.grey;
    }
  }
}