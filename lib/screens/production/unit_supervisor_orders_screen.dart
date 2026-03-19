import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

    final List<String> displayStages = ['All', 'All NSO', ...controller.factoryStages];

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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: TColors.primary, width: 1.5)),
                ),
              ),
            ),
          ),

          // --- 2. HORIZONTAL STAGE SELECTOR ---
          Container(
            height: 60,
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
                  Color baseColor = stage == 'All' ? TColors.primary : (stage == 'All NSO' ? Colors.deepOrange : _getStatusColor(stage));

                  int count = 0;
                  if (stage == 'All') {
                    count = controller.activeOrders.length;
                  } else if (stage == 'All NSO') {
                    count = controller.activeOrders.where((o) {
                      String s = o.status.toLowerCase();
                      return s != 'shipped' && s != 'delivered' && s != 'completed';
                    }).length;
                  } else {
                    count = controller.activeOrders.where((o) => o.status.toLowerCase() == stage.toLowerCase()).length;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 14, top: 8),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
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

                        if (count > 0)
                          Positioned(
                            top: -6,
                            right: -6,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : baseColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9), width: 2),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))]
                              ),
                              child: Text(
                                count.toString(),
                                style: TextStyle(color: isSelected ? baseColor : Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
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
              List<OrderModel> ordersToDisplay = controller.filteredOrders;

              if (controller.selectedFilterStage.value == 'All NSO') {
                ordersToDisplay = controller.activeOrders.where((o) {
                  String s = o.status.toLowerCase();
                  return s != 'shipped' && s != 'delivered' && s != 'completed';
                }).toList();

                if (controller.searchQuery.value.isNotEmpty) {
                  String query = controller.searchQuery.value.toLowerCase();
                  ordersToDisplay = ordersToDisplay.where((o) {
                    String orderNo = (o.manualOrderNo ?? o.id ?? "").toLowerCase();
                    String client = o.clientName.toLowerCase();
                    String product = o.productName.toLowerCase();
                    return orderNo.contains(query) || client.contains(query) || product.contains(query);
                  }).toList();
                }
              }

              if (ordersToDisplay.isEmpty) {
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

              var sortedOrders = List<OrderModel>.from(ordersToDisplay);

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
                      boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))],
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      order.manualOrderNo ?? "ID: ${order.id?.substring(0,6)}",
                                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : Colors.black87)
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
                              _buildInfoRow(isDark, Icons.business_rounded, "Client", order.clientName),
                              const SizedBox(height: 6),
                              _buildInfoRow(isDark, Icons.category_outlined, "Product", order.productName),
                              const SizedBox(height: 6),
                              _buildInfoRow(isDark, Icons.layers_outlined, "Quantity", "${order.quantity} Units"),
                              const SizedBox(height: 16),

                              // --- ACTION & HISTORY BUTTONS ---
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: _buildSolidGradient(TColors.primary),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [BoxShadow(color: TColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
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
                                  ),
                                  const SizedBox(width: 12),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(width: 8),
          Text("$label: ", style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 12, fontWeight: FontWeight.w700),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateStageDialog(BuildContext context, OrderModel order, UnitSupervisorController controller, bool isDark) {
    TextEditingController remarkController = TextEditingController();

    showModalBottomSheet(
        context: context,
        isScrollControlled: true, // Required for DraggableScrollableSheet
        backgroundColor: Colors.transparent, // Transparent so the sheet handles the background
        builder: (context) {
          // ✅ DRAGGABLE SCROLLABLE SHEET: Starts at 75%, expands to 90%, scrollable content
          return DraggableScrollableSheet(
            initialChildSize: 0.75, // Starts at 3/4 of the screen height
            minChildSize: 0.4,
            maxChildSize: 0.90, // Can be dragged up to 90% of screen height
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom, // Avoids keyboard
                  left: 24, right: 24, top: 16,
                ),
                child: SingleChildScrollView(
                  controller: scrollController, // Important: pass the scrollController
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- DRAG HANDLE ---
                      Center(
                        child: Container(
                          width: 40, height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                              color: isDark ? Colors.white24 : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(10)
                          ),
                        ),
                      ),

                      // --- 1. HEADER ROW: MOCKUP & ORDER ID ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 70, height: 70,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_not_supported_outlined, color: Colors.grey.shade400, size: 20),
                                const SizedBox(height: 4),
                                Text("Mockup\n(Soon)", textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                              "Order: ${order.manualOrderNo ?? order.id?.substring(0,6)}",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // --- 2. DETAILS BELOW HEADER ---
                      _buildInfoRow(isDark, Icons.business_rounded, "Client", order.clientName),
                      _buildInfoRow(isDark, Icons.category_rounded, "Product", "${order.productName} (${order.quantity} pcs)"),
                      _buildInfoRow(isDark, Icons.straighten_rounded, "Sizes", "Mixed/Standard"),

                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),

                      // --- 3. HORIZONTAL TIME TRACKER ---
                      Text("Stage Progression Time", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
                      const SizedBox(height: 12),
                      _buildHorizontalTimeline(order, isDark),
                      const SizedBox(height: 24),

                      // --- 4. UPDATE STAGE SELECTION ---
                      Text("Update Stage To:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: controller.factoryStages.map((stage) {
                          bool isCurrent = stage.toLowerCase() == order.status.toLowerCase();

                          return GestureDetector(
                            onTap: isCurrent ? null : () {
                              Get.back();
                              Get.defaultDialog(
                                title: "Confirm Update",
                                titleStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: isDark ? Colors.white : Colors.black87),
                                backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                content: Column(
                                  children: [
                                    Text('Changing status to', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                                    const SizedBox(height: 8),
                                    Text('"$stage"', style: TextStyle(color: TColors.primary, fontSize: 18, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                cancel: OutlinedButton(
                                  onPressed: () => Get.back(),
                                  style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5))),
                                  child: const Text("No", style: TextStyle(color: Colors.redAccent)),
                                ),
                                confirm: ElevatedButton(
                                  onPressed: () {
                                    Get.back();
                                    controller.updateProductionStage(order.id!, order.status, stage, remark: remarkController.text.trim());
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: TColors.primary),
                                  child: const Text("Confirm", style: TextStyle(color: Colors.white)),
                                ),
                              );
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
                      const SizedBox(height: 32),

                      // --- 5. REMARK TEXT FIELD (AT THE BOTTOM) ---
                      Text("Add Remark (Optional)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: remarkController,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "E.g., Fabric received, starting cut...",
                          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                          filled: true,
                          fillColor: isDark ? Colors.black26 : Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TColors.primary, width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              );
            },
          );
        }
    );
  }

  Widget _buildHorizontalTimeline(OrderModel order, bool isDark) {
    if (order.stageHistory.isEmpty) {
      return Text("No progression history available yet.", style: TextStyle(color: Colors.grey.shade500, fontSize: 12));
    }

    List<dynamic> history = List.from(order.stageHistory);
    history.sort((a, b) {
      DateTime timeA = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
      DateTime timeB = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
      return timeA.compareTo(timeB);
    });

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: history.length,
        itemBuilder: (context, index) {
          var current = history[index];
          DateTime currentTime = (current['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
          String currentStage = current['stage'] ?? 'Unknown';
          Color stageColor = _getStatusColor(currentStage);

          String timeTakenStr = '';
          if (index < history.length - 1) {
            var next = history[index + 1];
            DateTime nextTime = (next['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
            Duration diff = nextTime.difference(currentTime);

            if (diff.inDays > 0) {
              timeTakenStr = "${diff.inDays}d ${diff.inHours.remainder(24)}h";
            } else if (diff.inHours > 0) {
              timeTakenStr = "${diff.inHours}h ${diff.inMinutes.remainder(60)}m";
            } else {
              timeTakenStr = "${diff.inMinutes}m";
            }
          }

          return Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: stageColor.withValues(alpha: 0.15), shape: BoxShape.circle),
                    child: Icon(Icons.check_circle_rounded, color: stageColor, size: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(currentStage, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
                ],
              ),

              if (index < history.length - 1)
                Container(
                  width: 60,
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                          timeTakenStr,
                          style: TextStyle(fontSize: 9, color: isDark ? Colors.cyanAccent : Colors.cyan.shade700, fontWeight: FontWeight.bold)
                      ),
                      Container(height: 2, color: isDark ? Colors.white24 : Colors.grey.shade300),
                    ],
                  ),
                )
            ],
          );
        },
      ),
    );
  }

  void _showHistoryDialog(BuildContext context, OrderModel order, bool isDark) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) {
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
                    Expanded(child: Center(child: Text("No updates have been made yet.", style: TextStyle(color: Colors.grey.shade500))))
                  else
                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          var event = history[index];
                          DateTime time = DateTime.now();
                          if (event['timestamp'] != null) time = (event['timestamp'] as Timestamp).toDate();

                          String stage = event['stage'] ?? 'Unknown Stage';
                          String updater = event['updatedBy'] ?? 'System';
                          Color color = _getStatusColor(stage);

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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Colors.blue;
      case 'fab purchased': return Colors.pink;
      case 'fab ready': return Colors.lightGreen;
      case 'cutting': return Colors.orange;
      case 'cutting done': return Colors.deepOrange;
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
      case 'rejected': return Colors.red;
      case 'pending': return const Color(0xFFFFC107);
      default: return Colors.grey;
    }
  }
}