import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/admin/inventory_controller.dart';
import '../../utils/constants/colors.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize Controller
    final controller = Get.put(InventoryController());

    return Scaffold(
      appBar: AppBar(title: const Text("Fabric Inventory"), centerTitle: true),

      // ✅ ROLE-BASED ACTION BUTTON
      // Only visible if role contains "Supervisor" or is "Admin"
      floatingActionButton: Obx(() {
        final role = controller.currentUserRole.value;
        if (role.contains('Supervisor') || role == 'Admin') {
          return FloatingActionButton.extended(
            onPressed: () => _showAddStockDialog(context, controller),
            label: const Text("Inward Stock"),
            icon: const Icon(Icons.add),
            backgroundColor: TColors.primary,
          );
        } else {
          return const SizedBox.shrink(); // Hidden for everyone else
        }
      }),

      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.rawMaterials.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.layers_clear, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text("No Fabric Stock Found"),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.rawMaterials.length,
          itemBuilder: (context, index) {
            final item = controller.rawMaterials[index];
            final qty = (item['quantity'] as num).toDouble();

            // Logic: Low stock warning if < 500 meters
            final isLowStock = qty < 500;

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: isLowStock
                      ? Colors.red.withValues(alpha: 0.1)
                      : Colors.green.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.texture,
                    color: isLowStock ? Colors.red : Colors.green,
                  ),
                ),
                title: Text(
                  item['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text("Type: ${item['type']}"),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${qty.toStringAsFixed(1)} ${item['unit']}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isLowStock ? Colors.red : Colors.black,
                      ),
                    ),
                    if (isLowStock)
                      const Text(
                        "Low Stock",
                        style: TextStyle(fontSize: 10, color: Colors.red),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  // --- Dialog to Add Stock ---
  void _showAddStockDialog(
    BuildContext context,
    InventoryController controller,
  ) {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();

    Get.defaultDialog(
      title: "Inward Fabric",
      contentPadding: const EdgeInsets.all(16),
      content: Column(
        children: [
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(
              labelText: "Fabric Name",
              hintText: "e.g. Cotton",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: qtyCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Quantity",
              hintText: "e.g. 1000",
              suffixText: "Meters",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      confirm: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            if (nameCtrl.text.isNotEmpty && qtyCtrl.text.isNotEmpty) {
              controller.addStock(
                nameCtrl.text.trim(),
                double.tryParse(qtyCtrl.text) ?? 0.0,
                "Meters",
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: TColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text("Add to Stock"),
        ),
      ),
      cancel: SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: () => Get.back(),
          child: const Text("Cancel"),
        ),
      ),
    );
  }
}
