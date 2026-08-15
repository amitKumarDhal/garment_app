// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../controllers/production/unit_supervisor_controller.dart';
import '../../utils/constants/colors.dart';
import '../../data/models/order_model.dart';

// ✅ 1. Converted to StatefulWidget for Scroll Tracking
class UnitSupervisorOrdersScreen extends StatefulWidget {
  const UnitSupervisorOrdersScreen({super.key});

  @override
  State<UnitSupervisorOrdersScreen> createState() => _UnitSupervisorOrdersScreenState();
}

class _UnitSupervisorOrdersScreenState extends State<UnitSupervisorOrdersScreen> {
  late final UnitSupervisorController controller;

  // ✅ 2. Added UI Pagination Variables
  final ScrollController _scrollController = ScrollController();
  final RxInt visibleCount = 15.obs; // Start by showing 15 items

  @override
  void initState() {
    super.initState();
    controller = Get.put(UnitSupervisorController());

    // ✅ 3. Listen to scrolling to inject more items smoothly
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        // Prevent adding more if we already show everything
        if (visibleCount.value < controller.activeOrders.length) {
          visibleCount.value += 15;
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // --- GRADIENT HELPERS ---
  LinearGradient _buildSolidGradient(Color color) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [color.withValues(alpha: 0.8), color],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = TColors.getAdaptiveTextColor(context);

    final List<String> displayStages = ['All', 'All NSO', ...controller.factoryStages];

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : TColors.light,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 24,
        automaticallyImplyLeading: false,
        title: Text(
          "Stage Explorer",
          style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.5),
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
                onChanged: (value) {
                  visibleCount.value = 15; // ✅ Reset pagination on new search
                  controller.updateSearchQuery(value);
                },
                style: TextStyle(color: textColor, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Search by Order ID, Client, or Product...",
                  hintStyle: const TextStyle(color: TColors.textSecondary, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: TColors.textSecondary),
                  filled: true,
                  fillColor: isDark ? TColors.darkCard : Colors.white,
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
                          onTap: () {
                            visibleCount.value = 15; // ✅ Reset pagination when switching tabs
                            controller.setFilterStage(stage);
                          },
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
                                  border: Border.all(color: isDark ? TColors.dark : TColors.light, width: 2),
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

          // --- 3. FILTERED & PAGINATED ORDER LIST ---
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

              // Apply Sorting
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

              // ✅ PAGINATION SLICING
              int totalOrders = sortedOrders.length;
              int currentDisplayLimit = visibleCount.value;
              if (currentDisplayLimit > totalOrders) {
                currentDisplayLimit = totalOrders;
              }
              final slicedOrders = sortedOrders.sublist(0, currentDisplayLimit);

              return RefreshIndicator(
                color: TColors.primary,
                backgroundColor: isDark ? TColors.darkCard : Colors.white,
                onRefresh: () async {
                  visibleCount.value = 15; // ✅ Reset pagination on pull to refresh
                  await controller.fetchActiveOrders();
                },
                child: ordersToDisplay.isEmpty
                    ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 60, color: TColors.textSecondary),
                          SizedBox(height: 16),
                          Text("No matches found", style: TextStyle(color: TColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                )
                    : ListView.builder(
                  controller: _scrollController, // ✅ Attach scroll listener here
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.only(left: 24, right: 24, bottom: 100),
                  itemCount: currentDisplayLimit < totalOrders ? currentDisplayLimit + 1 : currentDisplayLimit,
                  itemBuilder: (context, index) {

                    // Show a tiny loading spinner at the bottom if more items are ready to load
                    if (index == currentDisplayLimit) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        child: Center(child: CircularProgressIndicator(color: TColors.primary)),
                      );
                    }

                    DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
                    var order = slicedOrders[index];
                    Color statusColor = _getStatusColor(order.status);
                    DateTime deadline = DateTime(order.deliveryDate.year, order.deliveryDate.month, order.deliveryDate.day);
                    int daysLeft = deadline.difference(today).inDays;

                    bool isOverdue = daysLeft < 0;
                    bool isDueToday = daysLeft == 0;
                    bool isDone = ['delivered', 'completed'].contains(order.status.toLowerCase());
                    bool isOutSrc = order.status.toLowerCase() == 'out src';

                    Color urgencyColor = isDone ? TColors.success : (isOutSrc ? Colors.indigoAccent : (isOverdue ? TColors.error : (isDueToday ? TColors.warning : TColors.textSecondary)));

                    String fabricRequired = controller.getFabricRequiredText(order.quantity, order.productName);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark ? TColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: TColors.getBorderColor(context)),
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
                                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: textColor)
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
                                            style: const TextStyle(fontSize: 8.5, color: TColors.textSecondary, fontStyle: FontStyle.italic, height: 1.2),
                                          ),
                                        ]
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(isDark, Icons.business_rounded, "Client", order.clientName, textColor),
                                const SizedBox(height: 6),
                                _buildInfoRow(isDark, Icons.category_outlined, "Product", order.productName, textColor),
                                const SizedBox(height: 6),
                                _buildInfoRow(isDark, Icons.layers_outlined, "Quantity", "${order.quantity} Units", textColor),

                                if (fabricRequired != "Not Specified") ...[
                                  const SizedBox(height: 6),
                                  _buildInfoRow(isDark, Icons.calculate_rounded, "Est. Fabric", fabricRequired, Colors.blueAccent),
                                ],

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
                                            onTap: () => _showUpdateStageDialog(context, order, controller, isDark, textColor),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(vertical: 14),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.edit_road_rounded, size: 16, color: Colors.white),
                                                  SizedBox(width: 8),
                                                  Text("UPDATE STAGE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
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
                                          border: Border.all(color: TColors.getBorderColor(context))
                                      ),
                                      child: IconButton(
                                        icon: Icon(Icons.history_rounded, color: textColor, size: 20),
                                        onPressed: () => _showHistoryDialog(context, order, isDark, textColor),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

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
                                Text(isOutSrc ? "OUTSOURCED" : (isOverdue ? "OVERDUE" : (isDueToday ? "DUE TODAY" : "ON TRACK")), style: TextStyle(color: urgencyColor, fontSize: 10, fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(bool isDark, IconData icon, String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 14, color: TColors.textSecondary),
          ),
          const SizedBox(width: 8),
          Text("$label: ", style: const TextStyle(color: TColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor, fontSize: 12, fontWeight: FontWeight.w800),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialRequirementCard(OrderModel order, bool isDark, Color textColor, UnitSupervisorController controller) {
    Map<String, Map<String, dynamic>> materials = {};

    for (var prod in order.products) {
      String savedFabric = (prod['fabricType'] ?? 'Not Specified').toString();
      String color = (prod['color'] ?? order.color ?? 'Not Specified').toString();
      String lowerFab = savedFabric.toLowerCase();
      String neckType = (prod['neckType'] ?? '').toString().toLowerCase();

      if (savedFabric != 'Not Specified' && savedFabric.isNotEmpty) {
        String lookupKey = "${lowerFab}_${color.toLowerCase()}";
        if (!materials.containsKey(lookupKey)) {
          materials[lookupKey] = {
            'name': savedFabric,
            'color': color,
            'lookupKey': lookupKey,
            'unit': lowerFab.contains('collar') ? 'pcs' : 'kg',
          };
        }
      }

      if (neckType.contains('collar') && !lowerFab.contains('collar')) {
        String colLookupKey = "collar_${color.toLowerCase()}";
        if (!materials.containsKey(colLookupKey)) {
          materials[colLookupKey] = {
            'name': 'Collar',
            'color': color,
            'lookupKey': colLookupKey,
            'unit': 'pcs',
          };
        }
      }
    }

    String estimatedKg = controller.getFabricRequiredText(order.quantity, order.productName);

    if (materials.isEmpty && estimatedKg == "Not Specified") return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_rounded, color: Colors.blue, size: 18),
              const SizedBox(width: 8),
              Text("Material Requirements", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: isDark ? Colors.blue.shade200 : Colors.blue.shade800)),
            ],
          ),
          const SizedBox(height: 12),

          if (estimatedKg != "Not Specified") ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calculate_rounded, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text("Total Fabric Needed: ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                  const Spacer(),
                  Text(estimatedKg, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.blue)),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          ...materials.values.map((mat) {
            return Obx(() {
              double inStock = controller.inventoryStock[mat['lookupKey']] ?? 0.0;
              String displayStock = mat['unit'] == 'pcs' ? inStock.toInt().toString() : inStock.toStringAsFixed(1);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "${mat['name']} (${mat['color']})",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "In Stock: $displayStock ${mat['unit']}",
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              );
            });
          }),
        ],
      ),
    );
  }

  void _showUpdateStageDialog(BuildContext context, OrderModel order, UnitSupervisorController controller, bool isDark, Color textColor) {
    TextEditingController remarkController = TextEditingController();

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? TColors.darkCard : TColors.lightCard,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.only(left: 24, right: 24, top: 16),
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40, height: 4,
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                        ),
                      ),

                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                                "Order #${order.manualOrderNo ?? order.id?.substring(0,6)}",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5)
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.deepOrange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.layers_rounded, size: 14, color: Colors.deepOrange),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${order.quantity} PCS",
                                    style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.w900, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Center(
                        child: GestureDetector(
                          onTap: () {
                            if (order.mockupUrl != null && order.mockupUrl!.isNotEmpty) {
                              _showFullScreenImage(context, order.mockupUrl!, order.manualOrderNo ?? "Unknown");
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            height: 280,
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black38 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: TColors.getBorderColor(context), width: 1.5),
                            ),
                            child: (order.mockupUrl != null && order.mockupUrl!.isNotEmpty)
                                ? CachedNetworkImage(
                              imageUrl: order.mockupUrl!,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: TColors.primary)),
                              errorWidget: (context, url, error) => Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image_rounded, color: TColors.error.withValues(alpha: 0.5), size: 40),
                                  const SizedBox(height: 8),
                                  const Text("Image Error", style: TextStyle(color: TColors.error, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            )
                                : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_not_supported_outlined, color: TColors.textSecondary.withValues(alpha: 0.5), size: 40),
                                const SizedBox(height: 8),
                                const Text("Waiting for Sales\nto upload mockup", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: TColors.textSecondary, fontWeight: FontWeight.bold, height: 1.2)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (order.mockupUrl != null && order.mockupUrl!.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Center(child: Text("Tap image to view full screen & download", style: TextStyle(fontSize: 10, color: TColors.textSecondary, fontStyle: FontStyle.italic))),
                        ),
                      const SizedBox(height: 24),

                      _buildMaterialRequirementCard(order, isDark, textColor, controller),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                            color: isDark ? Colors.black26 : TColors.light,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: TColors.getBorderColor(context))
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(isDark, Icons.business_rounded, "Client", order.clientName, textColor),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),

                            Row(
                              children: [
                                const Icon(Icons.inventory_2_rounded, size: 14, color: TColors.textSecondary),
                                const SizedBox(width: 8),
                                const Text("Products Details:", style: TextStyle(color: TColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                                const Spacer(),
                                Text("Total: ${order.quantity} pcs", style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w800)),
                              ],
                            ),
                            const SizedBox(height: 12),

                            ...order.products.map((prod) {
                              String name = prod['productName'] ?? prod['productDetails'] ?? 'Unknown Product';
                              String qty = (prod['qty'] ?? 0).toString();
                              String fabric = prod['fabricType'] ?? 'Not Specified';
                              String color = prod['color'] ?? 'Not Specified';
                              String sizes = prod['sizeDescription'] ?? 'Not Specified';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8, left: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(child: Text(name, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w800))),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: TColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                          child: Text("$qty pcs", style: const TextStyle(color: TColors.primary, fontSize: 10, fontWeight: FontWeight.w900)),
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text("Fabric: $fabric • Color: $color", style: const TextStyle(fontSize: 11, color: TColors.textSecondary)),
                                    if (sizes.isNotEmpty && sizes != 'Not Specified')
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text("Sizes: $sizes", style: const TextStyle(fontSize: 11, color: TColors.textSecondary)),
                                      )
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Stage Progression", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: textColor)),
                          GestureDetector(
                            onTap: () => _showHistoryDialog(context, order, isDark, textColor),
                            child: const Text("View All", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TColors.primary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildHorizontalTimeline(order, isDark, textColor),
                      const SizedBox(height: 24),

                      Text("Update Stage To:", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: textColor)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: controller.factoryStages.map((stage) {
                          bool isCurrent = stage.toLowerCase() == order.status.toLowerCase();

                          return GestureDetector(
                            onTap: isCurrent ? null : () {
                              Get.back();
                              _showConfirmationDialog(order, stage, controller, remarkController, isDark, textColor);
                            },
                            child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                    gradient: isCurrent ? _buildSolidGradient(TColors.primary) : null,
                                    color: isCurrent ? null : (isDark ? Colors.white10 : Colors.white),
                                    borderRadius: BorderRadius.circular(12),
                                    border: isCurrent ? null : Border.all(color: TColors.getBorderColor(context)),
                                    boxShadow: [
                                      if (!isCurrent && !isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))
                                    ]
                                ),
                                child: Text(
                                    stage,
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w700,
                                        color: isCurrent ? Colors.white : (isDark ? Colors.white70 : Colors.black87)
                                    )
                                )
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            },
          );
        }
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl, String orderNo) {
    Get.to(
          () => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          title: Text("Order $orderNo", style: const TextStyle(color: Colors.white, fontSize: 16)),
          actions: [
            IconButton(
              icon: const Icon(Icons.download_rounded, color: Colors.white),
              tooltip: 'Save to Gallery',
              onPressed: () => _downloadAndSaveImage(imageUrl, orderNo),
            ),
          ],
        ),
        body: Center(
          child: InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 1,
            maxScale: 4,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => const CircularProgressIndicator(color: Colors.white),
              errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white, size: 50),
            ),
          ),
        ),
      ),
      transition: Transition.fadeIn,
    );
  }

  Future<void> _downloadAndSaveImage(String url, String orderNo) async {
    try {
      Get.snackbar("Downloading...", "Saving mockup to your gallery.",
          backgroundColor: Colors.black87, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);

      final response = await http.get(Uri.parse(url));
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/mockup_$orderNo.jpg');
      await file.writeAsBytes(response.bodyBytes);
      await Gal.putImage(file.path);

      Get.snackbar("Success!", "Image saved to your photo gallery.",
          backgroundColor: Colors.green.shade800, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);

    } catch (e) {
      Get.snackbar("Error", "Could not save image: $e",
          backgroundColor: Colors.red.shade800, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _showConfirmationDialog(OrderModel order, String stage, UnitSupervisorController controller, TextEditingController remarkController, bool isDark, Color textColor) {
    remarkController.clear();

    Get.dialog(
      Dialog(
        backgroundColor: isDark ? TColors.darkCard : TColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: TColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.published_with_changes_rounded, color: TColors.primary, size: 24),
                ),
                const SizedBox(height: 12),

                Text("Confirm Update", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textColor)),
                const SizedBox(height: 4),

                RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                        style: const TextStyle(color: TColors.textSecondary, fontSize: 14, height: 1.3),
                        children: [
                          const TextSpan(text: "Move "),
                          TextSpan(text: "${order.quantity} pieces ", style: TextStyle(color: textColor, fontWeight: FontWeight.w900)),
                          const TextSpan(text: "to "),
                          TextSpan(text: '"$stage"', style: const TextStyle(color: TColors.primary, fontWeight: FontWeight.w900)),
                          const TextSpan(text: " ?"),
                        ]
                    )
                ),
                const SizedBox(height: 16),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Remark (Optional)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: remarkController,
                  maxLines: 2,
                  style: TextStyle(color: textColor, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "E.g., Fabric received...",
                    hintStyle: const TextStyle(color: TColors.textSecondary, fontSize: 12),
                    filled: true,
                    fillColor: isDark ? Colors.black26 : TColors.light,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TColors.primary, width: 1.2)),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: TColors.textSecondary.withValues(alpha: 0.2)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text("Cancel", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back();
                          controller.updateProductionStage(order.id!, order.status, stage, remark: remarkController.text.trim());
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: TColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Confirm", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildHorizontalTimeline(OrderModel order, bool isDark, Color textColor) {
    if (order.stageHistory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: isDark ? Colors.black26 : TColors.light, borderRadius: BorderRadius.circular(12)),
        child: const Text("No progression history available yet.", style: TextStyle(color: TColors.textSecondary, fontSize: 12)),
      );
    }

    List<dynamic> history = List.from(order.stageHistory);
    history.sort((a, b) {
      DateTime timeA = a['timestamp'] is String
          ? (DateTime.tryParse(a['timestamp'].toString()) ?? DateTime.now())
          : (a['timestamp'] is DateTime ? a['timestamp'] as DateTime : DateTime.now());
      DateTime timeB = b['timestamp'] is String
          ? (DateTime.tryParse(b['timestamp'].toString()) ?? DateTime.now())
          : (b['timestamp'] is DateTime ? b['timestamp'] as DateTime : DateTime.now());
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
          DateTime currentTime = current['timestamp'] is String
              ? (DateTime.tryParse(current['timestamp'].toString()) ?? DateTime.now())
              : (current['timestamp'] is DateTime ? current['timestamp'] as DateTime : DateTime.now());
          String currentStage = current['stage'] ?? 'Unknown';
          Color stageColor = _getStatusColor(currentStage);

          String timeTakenStr = '';
          if (index < history.length - 1) {
            var next = history[index + 1];
            DateTime nextTime = next['timestamp'] is String
                ? (DateTime.tryParse(next['timestamp'].toString()) ?? DateTime.now())
                : (next['timestamp'] is DateTime ? next['timestamp'] as DateTime : DateTime.now());
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
                  Text(currentStage, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor.withValues(alpha: 0.8))),
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
                          style: TextStyle(fontSize: 9, color: TColors.primary.withValues(alpha: 0.8), fontWeight: FontWeight.bold)
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

  void _showHistoryDialog(BuildContext context, OrderModel order, bool isDark, Color textColor) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: isDark ? TColors.darkCard : TColors.lightCard,
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
                      Text("Stage History", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: TColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(order.manualOrderNo ?? "Unknown ID", style: const TextStyle(color: TColors.primary, fontWeight: FontWeight.w900, fontSize: 12)),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (history.isEmpty)
                    const Expanded(child: Center(child: Text("No updates have been made yet.", style: TextStyle(color: TColors.textSecondary))))
                  else
                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          var event = history[index];
                          DateTime time = DateTime.now();
                          if (event['timestamp'] != null) {
                            time = event['timestamp'] is String
                                ? (DateTime.tryParse(event['timestamp'].toString()) ?? DateTime.now())
                                : (event['timestamp'] is DateTime ? event['timestamp'] as DateTime : DateTime.now());
                          }

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
                                      Text(stage, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.person_rounded, size: 12, color: TColors.textSecondary),
                                          const SizedBox(width: 4),
                                          Text("Updated by $updater", style: const TextStyle(fontSize: 12, color: TColors.textSecondary, fontWeight: FontWeight.w500)),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                                Text(
                                    DateFormat('dd MMM\nhh:mm a').format(time),
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: TColors.textSecondary, height: 1.3)
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
      case 'approved': return TColors.electricBlue;
      case 'fab purchased': return TColors.neonPink;
      case 'fab ready': return TColors.brightMint;
      case 'cutting': return TColors.cutting;
      case 'cutting done': return Colors.deepOrange;
      case 'printing': return TColors.printing;
      case 'printed': return Colors.cyan;
      case 'stitching': return TColors.stitching;
      case 'stitched': return Colors.brown;
      case 'packing': return TColors.packing;
      case 'packed': return Colors.deepPurple;
      case 'out src': return Colors.indigoAccent;
      case 'shipping':
      case 'shipped': return TColors.shipping;
      case 'delivered': return TColors.delivered;
      case 'completed': return TColors.success;
      case 'rejected': return TColors.error;
      case 'pending': return TColors.warning;
      default: return TColors.textSecondary;
    }
  }
}