import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/api_service.dart';

class PackingController extends GetxController {
  final cartonNo = TextEditingController();
  final styleNo = TextEditingController();
  final category = TextEditingController();
  final totalPieces = TextEditingController();
  final isLoading = false.obs;

  Future<void> submitPackingEntry(String? orderId) async {
    try {
      isLoading.value = true;
      final res = await ApiService.post('/production/packing', {
        'order_id': orderId,
        'carton_no': cartonNo.text.trim(),
        'style_no': styleNo.text.trim(),
        'category': category.text.trim().isEmpty ? 'M' : category.text.trim(),
        'total_pieces': int.tryParse(totalPieces.text.trim()) ?? 0,
        'breakdown': {},
      });

      if (res['success'] == true) {
        Get.snackbar("Success", "Packing entry saved", backgroundColor: Colors.green.withValues(alpha: 0.1));
        Get.back();
      }
    } catch (e) {
      Get.snackbar("Error", "Failed: $e");
    } finally {
      isLoading.value = false;
    }
  }

  final packingEntries = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchPackingEntries();
  }

  Future<void> fetchPackingEntries() async {
    try {
      final res = await ApiService.get('/production/activities');
      if (res['success'] == true && res['data'] != null) {
        final raw = List<Map<String, dynamic>>.from(res['data']);
        packingEntries.assignAll(raw.where((e) => e['stage']?.toString().toLowerCase() == 'packing').toList());
      }
    } catch (_) {}
  }

  var searchQuery = ''.obs;
  var activeFilter = 'All'.obs;
  List<Map<String, dynamic>> get filteredInventory {
    final q = searchQuery.value.toLowerCase().trim();
    if (q.isEmpty) return packingEntries;
    return packingEntries.where((e) =>
      (e['carton_no'] ?? '').toString().toLowerCase().contains(q) ||
      (e['style_no'] ?? '').toString().toLowerCase().contains(q)
    ).toList();
  }

  int get countSmall => packingEntries.where((e) => (e['category'] ?? '').toString().toUpperCase() == 'S').fold(0, (sum, e) => sum + (int.tryParse(e['total_pieces']?.toString() ?? '0') ?? 0));
  int get countMedium => packingEntries.where((e) => (e['category'] ?? '').toString().toUpperCase() == 'M').fold(0, (sum, e) => sum + (int.tryParse(e['total_pieces']?.toString() ?? '0') ?? 0));
  int get countLarge => packingEntries.where((e) => (e['category'] ?? '').toString().toUpperCase() == 'L').fold(0, (sum, e) => sum + (int.tryParse(e['total_pieces']?.toString() ?? '0') ?? 0));
  int get countXL => packingEntries.where((e) => (e['category'] ?? '').toString().toUpperCase() == 'XL').fold(0, (sum, e) => sum + (int.tryParse(e['total_pieces']?.toString() ?? '0') ?? 0));
  int get countXXL => packingEntries.where((e) => (e['category'] ?? '').toString().toUpperCase() == 'XXL').fold(0, (sum, e) => sum + (int.tryParse(e['total_pieces']?.toString() ?? '0') ?? 0));
  int get totalPiecesInFactory => packingEntries.fold(0, (sum, e) => sum + (int.tryParse(e['total_pieces']?.toString() ?? '0') ?? 0));

  var selectedCartonSize = 'Medium'.obs;
  List<String> get cartonSizes => ['Small', 'Medium', 'Large'];
  final boxContents = <String, TextEditingController>{
    'S': TextEditingController(),
    'M': TextEditingController(),
    'L': TextEditingController(),
    'XL': TextEditingController(),
    'XXL': TextEditingController(),
  };

  void calculateBoxTotal() {}
  final packingFormKey = GlobalKey<FormState>();
  List<String> get sizeOptions => ['S', 'M', 'L', 'XL', 'XXL'];
  var totalInBox = 0.obs;
  RxBool get isSubmitting => isLoading;
  Future<void> submitCarton() async => await submitPackingEntry(null);
}
