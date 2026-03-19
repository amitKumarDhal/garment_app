import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StockHistoryScreen extends StatelessWidget {
  final Map<String, dynamic> colorData;
  final String unit;
  final bool isDark;
  final String groupTitle;

  const StockHistoryScreen({
    super.key,
    required this.colorData,
    required this.unit,
    required this.isDark,
    required this.groupTitle
  });

  @override
  Widget build(BuildContext context) {
    List history = colorData['history'];

    // ✅ DYNAMIC RUNNING BALANCE CALCULATION
    // Since history is newest-first, we calculate backwards from the current balance
    double currentBal = (colorData['balance'] as num).toDouble();
    List<double> runningBalances = [];
    double tempBal = currentBal;

    for (int i = 0; i < history.length; i++) {
      // The balance AFTER this transaction occurred
      runningBalances.add(tempBal);

      var log = history[i];
      bool isIn = log['type'] == 'IN';
      double qty = (log['qty'] as num).toDouble();

      // Reverse the transaction to find what the balance was BEFORE this occurred
      if (isIn) {
        tempBal -= qty;
      } else {
        tempBal += qty;
      }
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                "${colorData['color']} $groupTitle",
                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w900, fontSize: 18)
            ),
            Text(
                "Current Balance: ${colorData['balance']} $unit",
                style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)
            ),
          ],
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        itemCount: history.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          var log = history[index];
          bool isIn = log['type'] == 'IN';
          String dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(log['date']);
          String supervisorName = log['supervisorName'] ?? "Unknown";

          // Grab the pre-calculated remaining balance for this specific row
          double remBal = runningBalances[index];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: isIn ? Colors.green.withValues(alpha: 0.1) : Colors.redAccent.withValues(alpha: 0.1),
                            shape: BoxShape.circle
                        ),
                        child: Icon(
                            isIn ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isIn ? Colors.green : Colors.redAccent,
                            size: 16
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                isIn ? "Stock In" : "Stock Out",
                                style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    color: isIn ? Colors.green : Colors.redAccent,
                                    letterSpacing: 0.5
                                )
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "$dateStr • $supervisorName",
                              style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // --- ✅ UPDATED RIGHT SIDE: Shows IN/OUT Qty + Remaining Balance ---
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${isIn ? '+' : '-'}${log['qty']} $unit",
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: isIn ? Colors.green : Colors.redAccent
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(4)
                      ),
                      child: Text(
                        "Rem: $remBal $unit",
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            color: isDark ? Colors.white70 : Colors.black54
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}