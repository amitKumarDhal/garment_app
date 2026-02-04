import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // Add this to pubspec.yaml for date formatting
import '../../controllers/admin/admin_controller.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/sizes.dart';
import '../../data/models/activity_item_model.dart';

class ProductionReportsScreen extends StatelessWidget {
  const ProductionReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Trigger fetch on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchReportData();
    });

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : TColors.light,
      appBar: AppBar(
        title: const Text("Production Reports"),
        backgroundColor: isDark ? TColors.dark : TColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- 1. FILTERS SECTION ---
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Picker Row
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: controller.reportDate.value,
                            firstDate: DateTime(2023),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            controller.setReportDate(picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Obx(
                                () => Text(
                                  DateFormat(
                                    'EEE, dd MMM yyyy',
                                  ).format(controller.reportDate.value),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Icon(Icons.calendar_today, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Horizontal Categories
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Obx(
                    () => Row(
                      children: [
                        _buildFilterChip(controller, "All"),
                        _buildFilterChip(controller, "Orders"),
                        _buildFilterChip(controller, "Cutting"),
                        _buildFilterChip(controller, "Printing"),
                        _buildFilterChip(controller, "Stitching"),
                        _buildFilterChip(controller, "Packing"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- 2. REPORT LIST ---
          Expanded(
            child: Obx(() {
              if (controller.isReportLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.reportList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.search_off,
                        size: 60,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "No records found for\n${DateFormat('dd MMM').format(controller.reportDate.value)}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(TSizes.md),
                itemCount: controller.reportList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _buildReportTile(
                    context,
                    controller.reportList[index],
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(AdminController controller, String label) {
    bool isSelected = controller.reportSection.value == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          if (selected) controller.setReportSection(label);
        },
        selectedColor: TColors.primary,
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
        backgroundColor: Colors.grey.withOpacity(0.1),
      ),
    );
  }

  Widget _buildReportTile(BuildContext context, ActivityItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String time = DateFormat('hh:mm a').format(item.time); // e.g. 02:30 PM

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  item.subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
