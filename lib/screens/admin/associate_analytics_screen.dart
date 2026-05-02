// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssociateAnalyticsScreen extends StatefulWidget {
  final Map<String, dynamic> agent;
  const AssociateAnalyticsScreen({super.key, required this.agent});

  @override
  State<AssociateAnalyticsScreen> createState() => _AssociateAnalyticsScreenState();
}

class _AssociateAnalyticsScreenState extends State<AssociateAnalyticsScreen> {
  // --- STATE VARIABLES ---
  String selectedTimeframe = "All Time";
  String selectedTab = "All";
  String selectedSubTab = "";
  String selectedToggle = "Orders"; // Orders, Units, Revenue

  // --- PARSED DATA ---
  List<dynamic> allOrders = [];
  List<dynamic> timeFilteredOrders = [];
  List<dynamic> fullyFilteredOrders = [];
  List<String> currentSubOptions = [];

  final currency = NumberFormat.compactCurrency(symbol: '₹', locale: 'en_IN', decimalDigits: 1);
  final numberFormat = NumberFormat.decimalPattern('en_IN');

  @override
  void initState() {
    super.initState();
    allOrders = widget.agent['clients'] ?? [];
    _processData();
  }

  // ===========================================================================
  // ✅ CORE DATA CRUNCHING ENGINE
  // ===========================================================================
  void _processData() {
    // 1. Apply Time Filter
    DateTime now = DateTime.now();
    timeFilteredOrders = allOrders.where((order) {
      if (selectedTimeframe == "All Time") return true;

      DateTime? orderDate;
      if (order['orderDate'] is Timestamp) {
        orderDate = (order['orderDate'] as Timestamp).toDate();
      } else if (order['orderDate'] is String) {
        orderDate = DateTime.tryParse(order['orderDate']);
      }

      if (orderDate == null) return true; // Include if no date to be safe

      if (selectedTimeframe == "Daily") {
        return now.difference(orderDate).inDays <= 1;
      } else if (selectedTimeframe == "Weekly") {
        return now.difference(orderDate).inDays <= 7;
      } else if (selectedTimeframe == "Monthly") {
        return now.difference(orderDate).inDays <= 30;
      }
      return true;
    }).toList();

    // 2. Extract Sub-Options based on the Selected Tab
    Set<String> options = {};
    if (selectedTab != "All") {
      for (var order in timeFilteredOrders) {
        List products = order['products'] ?? [];
        for (var p in products) {
          if (selectedTab == "Category" && p['productType'] != null) options.add(p['productType'].toString().trim());
          if (selectedTab == "Fabric" && p['fabricType'] != null) options.add(p['fabricType'].toString().trim());
          if (selectedTab == "Neck Type" && p['neckType'] != null) options.add(p['neckType'].toString().trim());
        }
      }
      currentSubOptions = options.toList()..sort();

      // Auto-select first sub-option if current is invalid
      if (currentSubOptions.isNotEmpty && !currentSubOptions.contains(selectedSubTab)) {
        selectedSubTab = currentSubOptions.first;
      } else if (currentSubOptions.isEmpty) {
        selectedSubTab = "";
      }
    }

    // 3. Apply Tab & Sub-Tab Filter
    fullyFilteredOrders = timeFilteredOrders.where((order) {
      if (selectedTab == "All" || selectedSubTab.isEmpty) return true;

      List products = order['products'] ?? [];
      for (var p in products) {
        if (selectedTab == "Category" && p['productType']?.toString().trim() == selectedSubTab) return true;
        if (selectedTab == "Fabric" && p['fabricType']?.toString().trim() == selectedSubTab) return true;
        if (selectedTab == "Neck Type" && p['neckType']?.toString().trim() == selectedSubTab) return true;
      }
      return false;
    }).toList();

    setState(() {}); // Trigger UI rebuild with new data
  }

  // ===========================================================================
  // ✅ HELPER EXTRACTORS
  // ===========================================================================
  double _getOrderRevenue(dynamic order) {
    return double.tryParse(order['effectiveRevenue']?.toString() ?? order['totalAmount']?.toString() ?? '0') ?? 0.0;
  }

  int _getOrderUnits(dynamic order) {
    int total = 0;
    if (order['products'] != null) {
      for (var p in order['products']) {
        total += int.tryParse(p['qty']?.toString() ?? '0') ?? 0;
      }
    }
    return total > 0 ? total : (int.tryParse(order['quantity']?.toString() ?? '0') ?? 0);
  }

  // ===========================================================================
  // ✅ UI BUILDER
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // --- CALCULATE METRICS ---
    double totalRevenue = 0;
    int totalOrders = fullyFilteredOrders.length;

    for (var o in fullyFilteredOrders) {
      totalRevenue += _getOrderRevenue(o);
    }
    double aov = totalOrders > 0 ? (totalRevenue / totalOrders) : 0;

    // --- CALCULATE REGIONAL DEMAND ---
    Map<String, Map<String, dynamic>> regionData = {};
    double maxSortValue = 0;

    for (var o in fullyFilteredOrders) {
      String state = (o['state']?.toString().trim().isNotEmpty == true) ? o['state'].toString().trim() : "Unknown";

      if (!regionData.containsKey(state)) {
        regionData[state] = {'orders': 0, 'units': 0, 'revenue': 0.0};
      }

      regionData[state]!['orders'] += 1;
      regionData[state]!['units'] += _getOrderUnits(o);
      regionData[state]!['revenue'] += _getOrderRevenue(o);
    }

    List<Map<String, dynamic>> regionsList = regionData.entries.map((e) {
      return {
        'state': e.key,
        'orders': e.value['orders'],
        'units': e.value['units'],
        'revenue': e.value['revenue'],
      };
    }).toList();

    // Sort the list based on toggle
    regionsList.sort((a, b) {
      if (selectedToggle == "Orders") return b['orders'].compareTo(a['orders']);
      if (selectedToggle == "Units") return b['units'].compareTo(a['units']);
      return b['revenue'].compareTo(a['revenue']);
    });

    // Find the max value for the progress bar percentage
    if (regionsList.isNotEmpty) {
      if (selectedToggle == "Orders") maxSortValue = regionsList.first['orders'].toDouble();
      if (selectedToggle == "Units") maxSortValue = regionsList.first['units'].toDouble();
      if (selectedToggle == "Revenue") maxSortValue = regionsList.first['revenue'].toDouble();
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Associate Insights", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
            Text(widget.agent['name'] ?? "Unknown Associate", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey)),
          ],
        ),
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🔹 TIME FILTER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Time Filter", style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey.shade600)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedTimeframe,
                      dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                      items: const [
                        DropdownMenuItem(value: "All Time", child: Text("All Time")),
                        DropdownMenuItem(value: "Monthly", child: Text("Monthly (30d)")),
                        DropdownMenuItem(value: "Weekly", child: Text("Weekly (7d)")),
                        DropdownMenuItem(value: "Daily", child: Text("Daily (24h)")),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          HapticFeedback.lightImpact();
                          setState(() => selectedTimeframe = val);
                          _processData();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            /// 🔹 TAB BAR
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildTabButton("All", isDark)),
                  Expanded(child: _buildTabButton("Category", isDark)),
                  Expanded(child: _buildTabButton("Fabric", isDark)),
                  Expanded(child: _buildTabButton("Neck Type", isDark)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            /// 🔹 SUB-TABS (Only shows if not "All")
            if (selectedTab != "All")
              Container(
                height: 36,
                margin: const EdgeInsets.only(bottom: 20),
                child: currentSubOptions.isEmpty
                    ? Center(child: Text("No $selectedTab data found.", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)))
                    : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: currentSubOptions.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    String option = currentSubOptions[index];
                    bool isSelected = selectedSubTab == option;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => selectedSubTab = option);
                        _processData();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.teal : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? Colors.teal : (isDark ? Colors.white10 : Colors.black12)),
                        ),
                        child: Text(
                          option,
                          style: TextStyle(
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            /// 🔹 PERFORMANCE CARD
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Expanded(child: _Metric(title: "ORDERS", value: numberFormat.format(totalOrders), color: Colors.blue)),
                  Container(width: 1, height: 40, color: isDark ? Colors.white10 : Colors.grey.shade200),
                  Expanded(child: _Metric(title: "REVENUE", value: currency.format(totalRevenue), color: Colors.green)),
                  Container(width: 1, height: 40, color: isDark ? Colors.white10 : Colors.grey.shade200),
                  Expanded(child: _Metric(title: "AOV", value: currency.format(aov), color: Colors.purple)),
                ],
              ),
            ),
            const SizedBox(height: 30),

            /// 🔹 SECTION TITLE
            const Text("Geographical Demand", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),

            /// 🔹 TOGGLE
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildToggleButton("Orders", isDark)),
                  Expanded(child: _buildToggleButton("Units", isDark)),
                  Expanded(child: _buildToggleButton("Revenue", isDark)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            /// 🔹 REGION LIST
            if (regionsList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Center(
                  child: Text("No geographic data for this selection.", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                ),
              )
            else
              ...List.generate(regionsList.length, (index) {
                final r = regionsList[index];

                String displayValue = "";
                double sortValue = 0;

                if (selectedToggle == "Orders") {
                  displayValue = "${r['orders']} Orders";
                  sortValue = r['orders'].toDouble();
                } else if (selectedToggle == "Units") {
                  displayValue = "${numberFormat.format(r['units'])} Pcs";
                  sortValue = r['units'].toDouble();
                } else {
                  displayValue = currency.format(r['revenue']);
                  sortValue = r['revenue'];
                }

                double percentage = maxSortValue > 0 ? (sortValue / maxSortValue) : 0.0;

                return _RegionCard(
                  rank: index + 1,
                  state: r['state'],
                  value: displayValue,
                  percentage: percentage,
                  isTop: index == 0,
                  isDark: isDark,
                );
              }),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- INTERNAL COMPONENT BUILDERS ---

  Widget _buildTabButton(String title, bool isDark) {
    bool selected = selectedTab == title;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => selectedTab = title);
        _processData();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? (isDark ? const Color(0xFF3A3A3C) : Colors.black) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton(String title, bool isDark) {
    bool selected = selectedToggle == title;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => selectedToggle = title);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.teal : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
            fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

// ====================== EXTRACTED COMPONENTS ======================

class _Metric extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _Metric({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5)),
        ),
      ],
    );
  }
}

class _RegionCard extends StatelessWidget {
  final int rank;
  final String state;
  final String value;
  final double percentage;
  final bool isTop;
  final bool isDark;

  const _RegionCard({
    required this.rank,
    required this.state,
    required this.value,
    required this.percentage,
    this.isTop = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTop ? Colors.teal : (isDark ? Colors.white10 : Colors.grey.shade200),
          width: isTop ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: isTop ? Colors.teal : (isDark ? Colors.white10 : Colors.grey.shade100),
                child: Text(
                  "#$rank",
                  style: TextStyle(
                      color: isTop ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: FontWeight.w900
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  state,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: isDark ? Colors.white : Colors.black87),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: isTop ? Colors.teal : (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
              ),
              LayoutBuilder(
                  builder: (context, constraints) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                      height: 6,
                      width: constraints.maxWidth * percentage,
                      decoration: BoxDecoration(
                        color: isTop ? Colors.teal : Colors.teal.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    );
                  }
              ),
            ],
          ),
        ],
      ),
    );
  }
}