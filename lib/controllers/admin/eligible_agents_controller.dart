// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class EligibleAgentsController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  var eligibleAgents = <Map<String, dynamic>>[].obs;
  var filteredAgents = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;

  var selectedMonth = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    fetchEligibleAgentsData();
  }

  void changeMonth(int offset) {
    selectedMonth.value = DateTime(selectedMonth.value.year, selectedMonth.value.month + offset, 1);
    fetchEligibleAgentsData();
  }

  // =====================================================================
  // ✅ 3-TIER SLAB BONUS LOGIC
  // =====================================================================
  double _calculateTieredBonus(double netAchievement, double dynamicTarget) {
    double surplus = netAchievement - dynamicTarget;
    if (surplus <= 0) return 0.0;

    double bonus = 0.0;
    double remainingSurplus = surplus;

    if (remainingSurplus > 0) {
      double slab1Amount = remainingSurplus > 50000 ? 50000 : remainingSurplus;
      bonus += (slab1Amount * 0.02);
      remainingSurplus -= slab1Amount;
    }
    if (remainingSurplus > 0) {
      double slab2Amount = remainingSurplus > 50000 ? 50000 : remainingSurplus;
      bonus += (slab2Amount * 0.015);
      remainingSurplus -= slab2Amount;
    }
    if (remainingSurplus > 0) {
      bonus += (remainingSurplus * 0.01);
    }
    return bonus;
  }

  Future<void> fetchEligibleAgentsData() async {
    isLoading.value = true;
    final fullCurrency = NumberFormat.currency(symbol: '₹', locale: 'en_IN', decimalDigits: 0);

    try {
      final usersSnap = await _db.collection('users').get();
      Map<String, Map<String, dynamic>> agentDataMap = {};

      for (var doc in usersSnap.docs) {
        final data = doc.data();
        String rawRole = (data['Role'] ?? data['role'] ?? '').toString().toUpperCase();

        if (rawRole.contains('SALES') || rawRole.contains('AGENT') || rawRole.contains('MANAGER') || ['SM', 'SSA', 'SC', 'JSA'].contains(rawRole)) {
          String name = (data['FullName'] ?? data['name'] ?? '').toString().trim();

          if (name.isNotEmpty) {
            String empId = (data['EmployeeID'] ?? data['employeeID'] ?? data['empId'] ?? doc.id.substring(0, 5)).toString();

            DateTime joined = DateTime(2020, 1, 1); // Failsafe
            var joinedRaw = data['CreatedAt'] ?? data['createdAt'];
            if (joinedRaw != null && joinedRaw is Timestamp) joined = joinedRaw.toDate();

            // ✅ PRODUCTION TARGETS
            double baseTarget = 100000.0;
            String displayRole = 'JSA';
            if (rawRole.contains('MANAGER') || rawRole == 'SM') { baseTarget = 150000.0; displayRole = 'SM'; }
            else if (rawRole.contains('SENIOR') || rawRole == 'SSA') { baseTarget = 150000.0; displayRole = 'SSA'; }
            else if (rawRole.contains('COORDINATOR') || rawRole == 'SC') { baseTarget = 200000.0; displayRole = 'SC'; }

            agentDataMap[name] = {
              ...data,
              "id": empId,
              "name": name,
              "avatar": name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase(),
              "joinedDate": joined,
              "baseTarget": baseTarget,
              "roleStr": displayRole,
              "monthlyNetMap": <String, double>{},
              "targetMonthGross": 0.0,
              "clients": [],
            };
          }
        }
      }

      final List<String> validRevenueStatuses = [
        'approved', 'fab purchased', 'fab ready', 'cutting', 'cutting done',
        'printing', 'printed', 'stitching', 'stitched', 'packing', 'packed',
        'out src', 'shipping', 'shipped', 'delivered', 'completed'
      ];

      String targetMonthKey = DateFormat('yyyy-MM').format(selectedMonth.value);
      final ordersSnap = await _db.collection('orders').get();

      for (var doc in ordersSnap.docs) {
        final o = doc.data();
        String agentName = (o['marketingPersonName'] ?? '').toString().trim();

        if (agentDataMap.containsKey(agentName)) {
          agentDataMap[agentName]!["clients"].add(o);

          String status = (o['status'] ?? '').toString().toLowerCase();
          bool isDeleted = o['isDeleted'] == true || o['isDeleted'] == "true";
          bool isDeleteRequested = o['isDeleteRequested'] == true || o['isDeleteRequested'] == "true";

          if (validRevenueStatuses.contains(status) && !isDeleted && !isDeleteRequested) {
            double effRev = double.tryParse(o['effectiveRevenue']?.toString() ?? '0') ?? 0.0;
            double totalAmt = double.tryParse(o['totalAmount']?.toString() ?? '0') ?? 0.0;
            double finalNet = (effRev > 0) ? effRev : totalAmt;

            DateTime orderDate = DateTime.now();
            if (o['orderDate'] != null && o['orderDate'] is Timestamp) {
              orderDate = (o['orderDate'] as Timestamp).toDate();
            } else if (o['orderDate'] is String) {
              orderDate = DateTime.tryParse(o['orderDate']) ?? DateTime.now();
            }

            String monthKey = DateFormat('yyyy-MM').format(orderDate);

            if (monthKey == targetMonthKey) {
              agentDataMap[agentName]!["targetMonthGross"] += totalAmt;
            }

            Map<String, double> netMap = agentDataMap[agentName]!["monthlyNetMap"];
            netMap[monthKey] = (netMap[monthKey] ?? 0.0) + finalNet;
          }
        }
      }

      List<Map<String, dynamic>> processedList = [];

      agentDataMap.forEach((agentName, agentObj) {
        Map<String, double> monthlyNetMap = agentObj["monthlyNetMap"];
        List<String> sortedMonths = monthlyNetMap.keys.toList()..sort();

        double currentTarget = agentObj["baseTarget"];
        String currentRole = agentObj["roleStr"];
        double accumulatedDue = 0.0;

        double targetMonthBonus = 0.0;
        double targetMonthNet = monthlyNetMap[targetMonthKey] ?? 0.0;

        DateTime joined = agentObj["joinedDate"];
        DateTime officialStartMonth = (joined.year == 2026 && joined.month == 2)
            ? DateTime(joined.year, joined.month, 1)
            : DateTime(joined.year, joined.month + 1, 1);

        int eeEligibleMonths = 0;
        Map<String, int> roleCounts = {};

        for (String mKey in sortedMonths) {
          DateTime loopMonth = DateFormat('yyyy-MM').parse(mKey);
          if (loopMonth.isBefore(officialStartMonth)) continue;
          if (loopMonth.year > selectedMonth.value.year || (loopMonth.year == selectedMonth.value.year && loopMonth.month > selectedMonth.value.month)) {
            continue;
          }

          double monthNet = monthlyNetMap[mKey] ?? 0.0;

          // ✅ 1. Calculate effective net for promotion (subtracts past dues)
          double effectiveForPromotion = monthNet - accumulatedDue;

          // ✅ 2. Dynamic Target & Surplus calculation
          double dynamicTarget = currentTarget + accumulatedDue;
          double surplus = monthNet - dynamicTarget;

          if (surplus > 0) {
            eeEligibleMonths++;
            double monthBonus = _calculateTieredBonus(monthNet, dynamicTarget);

            if (mKey == targetMonthKey) {
              targetMonthBonus = monthBonus;
            }
            // Deficit is fully cleared
            accumulatedDue = 0.0;
          } else {
            // Deficit rolls over to the next month
            accumulatedDue += (currentTarget - monthNet);
            // ✅ SAFETY CLAMP: Ensure deficit never inverts (matches SalesAgentController)
            if (accumulatedDue < 0) accumulatedDue = 0.0;
          }

          // ✅ 3. Evaluate Promotion for NEXT month's base target
          if (accumulatedDue <= 0 && currentRole != 'SM') {
            if (currentRole == 'JSA' && effectiveForPromotion >= 150000) {
              currentRole = 'SSA';
              currentTarget = 150000.0;
            }
            else if (currentRole == 'SSA' && effectiveForPromotion >= 200000) {
              currentRole = 'SC';
              currentTarget = 200000.0;
            }
          }

          roleCounts[currentRole] = (roleCounts[currentRole] ?? 0) + 1;
        }

        // ✅ STRICT PRODUCTION FILTER: ONLY show agents who earned a bonus > ₹0 THIS MONTH
        if (targetMonthBonus > 0) {
          List<String> roleParts = [];
          roleCounts.forEach((r, val) {
            if (val > 0) roleParts.add("$val month as $r");
          });

          agentObj["totalRev"] = fullCurrency.format(agentObj["targetMonthGross"]);
          agentObj["netAchievement"] = fullCurrency.format(targetMonthNet);
          agentObj["totalEE"] = fullCurrency.format(targetMonthBonus);
          agentObj["eeEligibleMonths"] = eeEligibleMonths.toString();
          agentObj["roleBreakdown"] = roleParts.join(", ");
          agentObj["rawMonthBonus"] = targetMonthBonus;

          processedList.add(agentObj);
        }
      });

      processedList.sort((a, b) => (b["rawMonthBonus"] as double).compareTo(a["rawMonthBonus"] as double));

      eligibleAgents.assignAll(processedList);
      filteredAgents.assignAll(processedList);
      isLoading.value = false;

    } catch (e) {
      debugPrint("Error: $e");
      isLoading.value = false;
    }
  }

  void searchAgent(String query) {
    if (query.isEmpty) {
      filteredAgents.assignAll(eligibleAgents);
    } else {
      filteredAgents.assignAll(
        eligibleAgents.where((a) => a['name'].toString().toLowerCase().contains(query.toLowerCase())).toList(),
      );
    }
  }
}