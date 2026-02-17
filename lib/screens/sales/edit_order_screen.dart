import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/order_model.dart';
import '../../controllers/sales/sales_agent_controller.dart';
import '../../utils/constants/colors.dart'; // Ensure TColors is imported

class EditOrderScreen extends StatefulWidget {
  final OrderModel order;

  const EditOrderScreen({super.key, required this.order});

  @override
  State<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  final controller = Get.find<SalesAgentController>();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController quantityController;
  late TextEditingController priceController;
  late TextEditingController detailsController;

  @override
  void initState() {
    super.initState();
    
    // 1. Quantity
    quantityController = TextEditingController(
      text: widget.order.quantity.toString(),
    );

    // 2. Price (Improved Logic)
    // First, try to calculate from Total / Qty (Safe fallback)
    double initialPriceVal = (widget.order.quantity > 0) 
        ? (widget.order.totalAmount / widget.order.quantity) 
        : 0.0;
    
    // If the products array has specific unit price data, use that instead
    if (widget.order.products.isNotEmpty) {
      initialPriceVal = double.tryParse(widget.order.products.first['price'].toString()) ?? initialPriceVal;
    }
    
    priceController = TextEditingController(text: initialPriceVal.toStringAsFixed(2));

    // 3. Details
    detailsController = TextEditingController(
      text: widget.order.productDetails ?? "",
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : Colors.grey[50],
      appBar: AppBar(
        title: const Text("Edit Order"),
        centerTitle: true,
        backgroundColor: Colors.purple, // Matching your app theme
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- WARNING CARD ---
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Changing Quantity or Price will auto-calculate the new Total & Balance.",
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.orange[200]
                              : Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                "Order Details",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),

              // --- FORM CONTAINER ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 1. Quantity Input
                    _buildModernTextField(
                      controller: quantityController,
                      label: "Quantity (Pieces)",
                      icon: Icons.layers,
                      isNumber: true,
                      isDark: isDark,
                      borderColor: borderColor,
                      validator: (val) => (val == null || val.isEmpty)
                          ? "Enter quantity"
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // 2. Price Input
                    _buildModernTextField(
                      controller: priceController,
                      label: "Unit Price (₹)",
                      icon: Icons.currency_rupee,
                      isNumber: true,
                      isDark: isDark,
                      borderColor: borderColor,
                      validator: (val) =>
                          (val == null || val.isEmpty) ? "Enter price" : null,
                    ),
                    const SizedBox(height: 20),

                    // 3. Details Input
                    _buildModernTextField(
                      controller: detailsController,
                      label: "Product Notes / Instructions",
                      icon: Icons.description,
                      isNumber: false,
                      maxLines: 4,
                      isDark: isDark,
                      borderColor: borderColor,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // --- UPDATE BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: Obx(
                  () => ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : _submitUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                      shadowColor: Colors.purple.withOpacity(0.4),
                    ),
                    child: controller.isLoading.value
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save_as, size: 22),
                              SizedBox(width: 8),
                              Text(
                                "Save Changes",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Custom Widget for Consistent UI ---
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    required Color borderColor,
    bool isNumber = false,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: Colors.purple.withOpacity(0.7)),
        filled: true,
        fillColor: isDark ? Colors.black.withOpacity(0.2) : Colors.grey[50],
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.purple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  void _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    // Parse inputs
    int newQty = int.tryParse(quantityController.text) ?? widget.order.quantity;
    double newPrice = double.tryParse(priceController.text) ?? 0.0;

    // Call Controller (Standard)
    await controller.updateOrder(
      widget.order,
      newQty,
      newPrice,
      detailsController.text,
    );

    Get.back();
  }
}