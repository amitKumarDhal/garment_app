import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class EligibleAgentsController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Observables ---
  var eligibleAgents = <Map<String, dynamic>>[].obs;
  var filteredAgents = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchEligibleAgentsData();
  }

  // =====================================================================
  // ✅ TIERED SLAB BONUS LOGIC
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

  // --- Core Calculation Engine ---
  Future<void> fetchEligibleAgentsData() async {
    isLoading.value = true;

    final fullCurrency = NumberFormat.currency(symbol: '₹', locale: 'en_IN', decimalDigits: 0);

    try {
      final usersSnap = await _db.collection('users').get();
      Map<String, Map<String, dynamic>> baseAgentMap = {};

      for (var doc in usersSnap.docs) {
        final data = doc.data();
        String rawRole = (data['Role'] ?? data['role'] ?? '').toString().toUpperCase();

        if (rawRole.contains('SALES') || rawRole.contains('AGENT') || rawRole.contains('MANAGER') || ['SM', 'SSA', 'SC', 'JSA'].contains(rawRole)) {
          String name = data['FullName'] ?? data['name'] ?? 'Unknown';

          if (name != 'Unknown') {
            String empId = (data['EmployeeID'] ?? data['employeeID'] ?? data['employeeId'] ?? data['empId'] ?? doc.id.substring(0, 5)).toString();

            DateTime joined = DateTime.now();
            var joinedRaw = data['CreatedAt'] ?? data['createdAt'];
            if (joinedRaw != null && joinedRaw is Timestamp) joined = joinedRaw.toDate();

            int monthsActive = DateTime.now().difference(joined).inDays ~/ 30;
            if (monthsActive <= 0) monthsActive = 1;

            double baseTarget = 100000;
            String displayRole = 'JSA';

            if (rawRole.contains('MANAGER') || rawRole == 'SM') {
              baseTarget = 150000; displayRole = 'SM';
            } else if (rawRole.contains('SENIOR') || rawRole == 'SSA') {
              baseTarget = 150000; displayRole = 'SSA';
            } else if (rawRole.contains('COORDINATOR') || rawRole == 'SC') {
              baseTarget = 200000; displayRole = 'SC';
            }

            baseAgentMap[name] = {
              "id": empId,
              "name": name,
              "avatar": name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase(),
              "role": displayRole,
              "joinedDate": joined,
              "monthsActive": monthsActive,
              "baseTargetAmount": baseTarget,
              "grossRevenue": 0.0,
              "monthlyNet": <String, double>{},
            };
          }
        }
      }

      final List<String> validRevenueStatuses = [
        'approved', 'fab purchased', 'fab ready', 'cutting', 'cutting done',
        'printing', 'printed', 'stitching', 'stitched', 'packing', 'packed',
        'out src', 'shipping', 'shipped', 'delivered', 'completed'
      ];

      _db.collection('orders').snapshots().listen((snapshot) {
        Map<String, Map<String, dynamic>> liveAgentMap = {};
        baseAgentMap.forEach((key, value) {
          liveAgentMap[key] = Map.from(value);
          liveAgentMap[key]!['monthlyNet'] = <String, double>{};
        });

        for (var doc in snapshot.docs) {
          final data = doc.data();
          if (data['isDeleted'] == true || data['isDeleteRequested'] == true) continue;

          String agentName = data['marketingPersonName'] ?? '';

          if (liveAgentMap.containsKey(agentName)) {
            var agent = liveAgentMap[agentName]!;
            String status = (data['status'] ?? '').toString().toLowerCase();

            if (validRevenueStatuses.contains(status)) {
              double effRev = double.tryParse(data['effectiveRevenue']?.toString() ?? '0') ?? 0.0;
              double totalAmt = double.tryParse(data['totalAmount']?.toString() ?? '0') ?? 0.0;
              double finalNet = (effRev > 0) ? effRev : totalAmt;

              DateTime orderDate = DateTime.now();
              if (data['orderDate'] != null && data['orderDate'] is Timestamp) {
                orderDate = (data['orderDate'] as Timestamp).toDate();
              }
              String monthKey = DateFormat('yyyy-MM').format(orderDate);

              agent["grossRevenue"] += totalAmt;
              agent["monthlyNet"][monthKey] = (agent["monthlyNet"][monthKey] ?? 0.0) + finalNet;
            }
          }
        }

        List<Map<String, dynamic>> processedList = [];

        // ✅ Get the current month string (e.g., "2026-04")
        String currentMonthKey = DateFormat('yyyy-MM').format(DateTime.now());

        for (var agent in liveAgentMap.values) {
          double rawGross = agent["grossRevenue"];
          int monthsActive = agent["monthsActive"];

          Map<String, double> monthlyNetMap = agent["monthlyNet"];
          List<String> sortedMonths = monthlyNetMap.keys.toList()..sort();

          double currentTarget = agent["baseTargetAmount"];
          String currentRole = agent["role"];
          double accumulatedDue = 0.0;

          double totalExtraRevenue = 0.0;
          double totalCalculatedBonus = 0.0;
          double currentMonthBonus = 0.0; // ✅ Tracker specifically for THIS month

          int eeEligibleMonths = 0;
          Map<String, int> roleCounts = {};

          DateTime joinedDate = agent["joinedDate"];
          DateTime officialStartMonth = (joinedDate.year == 2026 && joinedDate.month == 2)
              ? DateTime(joinedDate.year, joinedDate.month, 1)
              : DateTime(joinedDate.year, joinedDate.month + 1, 1);

          for (String mKey in sortedMonths) {
            DateTime loopMonth = DateFormat('yyyy-MM').parse(mKey);
            if (loopMonth.isBefore(officialStartMonth)) continue;

            double monthNet = monthlyNetMap[mKey] ?? 0.0;

            if (accumulatedDue <= 0 && currentRole != 'SM') {
              if (currentRole == 'JSA' && monthNet >= 150000) { currentRole = 'SSA'; currentTarget = 150000.0; }
              else if (currentRole == 'SSA' && monthNet >= 200000) { currentRole = 'SC'; currentTarget = 200000.0; }
            }

            roleCounts[currentRole] = (roleCounts[currentRole] ?? 0) + 1;

            double dynamicTarget = currentTarget + accumulatedDue;
            double surplus = monthNet - dynamicTarget;

            if (surplus > 0) {
              eeEligibleMonths++;
              totalExtraRevenue += surplus;

              double monthBonus = _calculateTieredBonus(monthNet, dynamicTarget);
              totalCalculatedBonus += monthBonus;

              // ✅ Check if the loop is currently processing THIS month
              if (mKey == currentMonthKey) {
                currentMonthBonus = monthBonus;
              }

              accumulatedDue = 0.0;
            } else {
              accumulatedDue += (currentTarget - monthNet);
            }
          }

          // ✅ ONLY Add them to the list if they earned a bonus THIS CURRENT MONTH!
          if (currentMonthBonus > 0) {
            int countedMonths = roleCounts.values.fold(0, (total, val) => total + val);
            if (monthsActive > countedMonths) {
              roleCounts[agent["role"]] = (roleCounts[agent["role"]] ?? 0) + (monthsActive - countedMonths);
            }

            List<String> roleParts = [];
            roleCounts.forEach((r, val) {
              if (val > 0) roleParts.add("$val month as $r");
            });

            processedList.add({
              "id": agent["id"],
              "name": agent["name"],
              "avatar": agent["avatar"],
              "totalRev": fullCurrency.format(rawGross),
              "extraRevenue": fullCurrency.format(totalExtraRevenue),
              "eeEligibleMonths": eeEligibleMonths.toString(),
              "totalEE": fullCurrency.format(totalCalculatedBonus),
              "roleBreakdown": roleParts.join(", "),
              "rawCurrentMonthBonus": currentMonthBonus, // ✅ Added for sorting
            });
          }
        }

        // ✅ Sort by highest earner THIS MONTH
        processedList.sort((a, b) => (b["rawCurrentMonthBonus"] as double).compareTo(a["rawCurrentMonthBonus"] as double));

        eligibleAgents.assignAll(processedList);

        if (filteredAgents.isNotEmpty && eligibleAgents.length != filteredAgents.length) {
          searchAgent('');
        } else {
          filteredAgents.assignAll(processedList);
        }

        isLoading.value = false;
      });

    } catch (e) {
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