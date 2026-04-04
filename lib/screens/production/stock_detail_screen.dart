import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'stock_history_screen.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/inventory_constants.dart';

class StockDetailScreen extends StatelessWidget {
  final Map<String, dynamic> groupData;
  final String unit;
  final bool isDark;

  const StockDetailScreen({
    super.key,
    required this.groupData,
    required this.unit,
    required this.isDark
  });

  @override
  Widget build(BuildContext context) {
    List colorsList = groupData['colorsList'];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        title: Text(
            groupData['title'],
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w900)
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        itemCount: colorsList.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          var c = colorsList[index];

          // 1. Extract the absolute latest log just for THIS specific color
          List history = c['history'] ?? [];
          Map<String, dynamic>? latestLog;
          if (history.isNotEmpty) {
            latestLog = history.first;
          }

          // 2. ✅ FIX: Pull Date and Name DIRECTLY from the latestLog
          DateTime lastUpdateDate = DateTime.now();
          String updatedBy = "Unknown";

          if (latestLog != null) {
            // Controller already parsed it to DateTime, so we can cast it directly safely
            lastUpdateDate = latestLog['date'] as DateTime? ?? DateTime.now();
            updatedBy = latestLog['supervisorName'] ?? "Unknown";
          }

          String dateStr = DateFormat('dd MMM, hh:mm a').format(lastUpdateDate);

          bool isLatestIn = latestLog?['type'] == 'IN';
          Color actionColor = latestLog == null ? Colors.grey : (isLatestIn ? Colors.green : Colors.redAccent);

          // Format the display name (removing the product suffix if it exists for custom colors)
          String displayName = c['color'].toString().split(' (').first;

          return GestureDetector(
            onTap: () => Get.to(() => StockHistoryScreen(colorData: c, unit: unit, isDark: isDark, groupTitle: groupData['title'])),
            child: Card(
              elevation: isDark ? 0 : 2,
              margin: EdgeInsets.zero,
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05), width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- TOP ROW: Color Indicator & Balance ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                                ),
                                child: Icon(Icons.circle, color: Color(InventoryConstants.getHexForColor(displayName)), size: 16),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                    displayName,
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: isDark ? Colors.white : Colors.black87)
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Right Side Balance Display
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "IN STOCK",
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: TColors.primary.withValues(alpha: 0.8), letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 2),
                            Text(
                                "${c['balance']} $unit",
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: TColors.primary)
                            ),
                          ],
                        )
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // --- BOTTOM ROW: Last Update & Action Badge ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.history_toggle_off_rounded, size: 12, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Text("Last updated", style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "$dateStr • $updatedBy",
                                style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 12, fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Contextual Last Action Badge
                        if (latestLog != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: actionColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(isLatestIn ? Icons.arrow_downward : Icons.arrow_upward, size: 10, color: actionColor),
                                const SizedBox(width: 4),
                                Text(
                                    "${isLatestIn ? '+' : '-'}${latestLog['qty']} $unit",
                                    style: TextStyle(fontWeight: FontWeight.w900, color: actionColor, fontSize: 11)
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}