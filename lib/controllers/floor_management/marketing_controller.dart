import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class MarketingController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Observables ---
  var allAgents = <Map<String, dynamic>>[].obs;
  var filteredAgents = <Map<String, dynamic>>[].obs;
  var filteredClients = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDynamicAgentStats();
  }

  void initClients(List<dynamic> clients) {
    filteredClients.assignAll(clients.cast<Map<String, dynamic>>());
  }

  void searchClient(List<dynamic> allClients, String query) {
    final clients = allClients.cast<Map<String, dynamic>>();

    if (query.isEmpty) {
      filteredClients.assignAll(clients);
    } else {
      String lowerQuery = query.toLowerCase();
      filteredClients.assignAll(
        clients.where((c) {
          final name = (c['clientName'] ?? c['name'] ?? "").toString().toLowerCase();
          final org = (c['organization'] ?? c['org'] ?? "").toString().toLowerCase();
          return name.contains(lowerQuery) || org.contains(lowerQuery);
        }).toList(),
      );
    }
  }

  // =====================================================================
  // ✅ TIERED SLAB BONUS LOGIC
  // =====================================================================
  double _calculateTieredBonus(double netAchievement, double dynamicTarget) {
    double surplus = netAchievement - dynamicTarget;

    if (surplus <= 0) {
      return 0.0;
    }

    double bonus = 0.0;
    double remainingSurplus = surplus;

    // Slab 1: 2% on first 50k
    if (remainingSurplus > 0) {
      double slab1Amount = remainingSurplus > 50000 ? 50000 : remainingSurplus;
      bonus += (slab1Amount * 0.02);
      remainingSurplus -= slab1Amount;
    }

    // Slab 2: 1.5% on next 50k
    if (remainingSurplus > 0) {
      double slab2Amount = remainingSurplus > 50000 ? 50000 : remainingSurplus;
      bonus += (slab2Amount * 0.015);
      remainingSurplus -= slab2Amount;
    }

    // Slab 3: 1% on anything above 1 Lakh surplus
    if (remainingSurplus > 0) {
      bonus += (remainingSurplus * 0.01);
    }

    return bonus;
  }

  // --- 3. The Real-Time Aggregator ---
  Future<void> fetchDynamicAgentStats() async {
    isLoading.value = true;

    final fullCurrency = NumberFormat.currency(symbol: '₹', locale: 'en_IN', decimalDigits: 0);
    final compactCurrency = NumberFormat.compactCurrency(symbol: '₹', locale: 'en_IN', decimalDigits: 1);

    try {
      // ✅ Step 1: Fetch all users to get base stats, targets, IDs, and join dates
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
            if (joinedRaw != null && joinedRaw is Timestamp) {
              joined = joinedRaw.toDate();
            }

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

            double totalTarget = baseTarget * monthsActive;

            baseAgentMap[name] = {
              "id": empId,
              "name": name,
              "avatar": name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase(),
              "role": displayRole,
              "joinedDate": joined, // ✅ Needed for accurate monthly loop
              "monthsActive": monthsActive,
              "baseTargetAmount": baseTarget, // ✅ Needed for monthly target math
              "totalTarget": compactCurrency.format(totalTarget),
              "roleHistory": [
                {"text": "$monthsActive Month(s) $displayRole (${compactCurrency.format(baseTarget)})"}
              ],
              "grossRevenue": 0.0,
              "netAchievement": 0.0,
              "monthlyNet": <String, double>{}, // ✅ Tracker for Month-by-Month Net
              "orders": 0,
              "clients": <Map<String, dynamic>>[],
              "uniqueClientNames": <String>{},
            };
          }
        }
      }

      final List<String> validRevenueStatuses = [
        'approved', 'fab purchased', 'fab ready', 'cutting', 'cutting done',
        'printing', 'printed', 'stitching', 'stitched', 'packing', 'packed',
        'out src', 'shipping', 'shipped', 'delivered', 'completed'
      ];

      // ✅ Step 2: Listen to real-time order updates
      _db.collection('orders').snapshots().listen((snapshot) {

        Map<String, Map<String, dynamic>> liveAgentMap = {};
        baseAgentMap.forEach((key, value) {
          liveAgentMap[key] = Map.from(value);
          liveAgentMap[key]!['clients'] = <Map<String, dynamic>>[];
          liveAgentMap[key]!['uniqueClientNames'] = <String>{};
          liveAgentMap[key]!['monthlyNet'] = <String, double>{};
        });

        for (var doc in snapshot.docs) {
          final data = doc.data();
          if (data['isDeleted'] == true || data['isDeleteRequested'] == true) continue;

          String agentName = data['marketingPersonName'] ?? '';

          if (!liveAgentMap.containsKey(agentName) && agentName.isNotEmpty && agentName != 'Unknown') {
            liveAgentMap[agentName] = {
              "id": "N/A",
              "name": agentName,
              "avatar": agentName.length >= 2 ? agentName.substring(0, 2).toUpperCase() : agentName.toUpperCase(),
              "role": "Former Agent",
              "joinedDate": DateTime.now(),
              "monthsActive": 1,
              "baseTargetAmount": 0.0,
              "totalTarget": "N/A",
              "roleHistory": [{"text": "Historical Data"}],
              "grossRevenue": 0.0,
              "netAchievement": 0.0,
              "monthlyNet": <String, double>{},
              "orders": 0,
              "clients": <Map<String, dynamic>>[],
              "uniqueClientNames": <String>{},
            };
          }

          if (liveAgentMap.containsKey(agentName)) {
            var agent = liveAgentMap[agentName]!;

            agent["clients"].add({...data, 'id': doc.id});
            agent["uniqueClientNames"].add((data['clientName'] ?? 'Unknown').toString().toLowerCase().trim());
            agent["orders"] += 1;

            String status = (data['status'] ?? '').toString().toLowerCase();

            if (validRevenueStatuses.contains(status)) {
              double effRev = double.tryParse(data['effectiveRevenue']?.toString() ?? '0') ?? 0.0;
              double totalAmt = double.tryParse(data['totalAmount']?.toString() ?? '0') ?? 0.0;
              double finalNet = (effRev > 0) ? effRev : totalAmt;

              // ✅ Parse order date to group revenue into specific months
              DateTime orderDate = DateTime.now();
              if (data['orderDate'] != null && data['orderDate'] is Timestamp) {
                orderDate = (data['orderDate'] as Timestamp).toDate();
              }
              String monthKey = DateFormat('yyyy-MM').format(orderDate);

              agent["grossRevenue"] += totalAmt;
              agent["netAchievement"] += finalNet;
              agent["monthlyNet"][monthKey] = (agent["monthlyNet"][monthKey] ?? 0.0) + finalNet;
            }
          }
        }

        // ✅ Step 3: Format the final list & Calculate Accurate Monthly Rollover Bonus
        final List<Map<String, dynamic>> dynamicList = liveAgentMap.values.map((agent) {
          double rawGross = agent["grossRevenue"];
          double rawNet = agent["netAchievement"];
          int orders = agent["orders"];

          // AOV
          double avgRev = orders > 0 ? (rawNet / orders) : 0.0;

          // ✅ PERFECT MONTH-BY-MONTH CALCULATOR
          Map<String, double> monthlyNetMap = agent["monthlyNet"];
          List<String> sortedMonths = monthlyNetMap.keys.toList()..sort();

          double currentTarget = agent["baseTargetAmount"];
          double accumulatedDue = 0.0;
          double totalCalculatedBonus = 0.0;

          DateTime joinedDate = agent["joinedDate"];
          DateTime officialStartMonth;
          if (joinedDate.year == 2026 && joinedDate.month == 2) {
            officialStartMonth = DateTime(joinedDate.year, joinedDate.month, 1);
          } else {
            officialStartMonth = DateTime(joinedDate.year, joinedDate.month + 1, 1);
          }

          // Loop through every month they had sales
          for (String mKey in sortedMonths) {
            DateTime loopMonth = DateFormat('yyyy-MM').parse(mKey);
            if (loopMonth.isBefore(officialStartMonth)) continue;

            double monthNet = monthlyNetMap[mKey] ?? 0.0;
            double dynamicTarget = currentTarget + accumulatedDue; // Add prev dues to target
            double surplus = monthNet - dynamicTarget;

            if (surplus > 0) {
              totalCalculatedBonus += _calculateTieredBonus(monthNet, dynamicTarget);
              accumulatedDue = 0.0; // Bonus earned, dues cleared!
            } else {
              accumulatedDue += (currentTarget - monthNet); // Target missed, dues roll over
            }
          }

          return {
            "id": agent["id"],
            "name": agent["name"],
            "avatar": agent["avatar"],
            "role": agent["role"],
            "monthsActive": agent["monthsActive"],
            "totalTarget": agent["totalTarget"],
            "roleHistory": agent["roleHistory"],
            "rawRevenue": rawNet, // Used for sorting
            "grossRevenue": fullCurrency.format(rawGross),   // Passed to UI
            "netAchievement": fullCurrency.format(rawNet),   // Passed to UI
            "orders": orders,
            "avgRevenue": compactCurrency.format(avgRev),
            "extraEarning": compactCurrency.format(totalCalculatedBonus), // ✅ Exact accurate bonus!
            "clients": agent["clients"],
            "uniqueClientsCount": (agent["uniqueClientNames"] as Set).length,
          };
        }).toList();

        dynamicList.sort((a, b) => (b["rawRevenue"] as double).compareTo(a["rawRevenue"] as double));

        allAgents.assignAll(dynamicList);

        if (filteredAgents.isNotEmpty && allAgents.length != filteredAgents.length) {
          searchAgent('');
        } else {
          filteredAgents.assignAll(dynamicList);
        }

        isLoading.value = false;
      });

    } catch (e) {
      isLoading.value = false;
    }
  }

  void searchAgent(String query) {
    if (query.isEmpty) {
      filteredAgents.assignAll(allAgents);
    } else {
      filteredAgents.assignAll(
        allAgents.where((a) => a['name'].toString().toLowerCase().contains(query.toLowerCase())).toList(),
      );
    }
  }
}