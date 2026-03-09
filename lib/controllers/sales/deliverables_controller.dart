import 'package:get/get.dart';
import '../../data/models/order_model.dart';
import 'sales_manager_controller.dart';

class DeliverablesController extends GetxController {
  final SalesManagerController smController = Get.find<SalesManagerController>();

  // Currently selected date on the timeline
  var selectedDate = DateTime.now().obs;

  // Change the selected date
  void selectDate(DateTime date) {
    selectedDate.value = date;
  }

  // 1. GET ORDERS EXACTLY FOR SELECTED DATE
  List<OrderModel> get ordersForSelectedDate {
    return smController.activeOrders.where((order) {
      return order.deliveryDate.year == selectedDate.value.year &&
          order.deliveryDate.month == selectedDate.value.month &&
          order.deliveryDate.day == selectedDate.value.day;
    }).toList();
  }

  // 2. GET "AT RISK" ORDERS (Deadline <= 3 days away AND NOT ready for delivery)
  List<OrderModel> get atRiskOrders {
    // These statuses mean the order is safe and shouldn't trigger a warning
    List<String> safeStatuses = ['packed', 'shipping', 'shipped', 'delivered', 'completed', 'rejected'];

    // Normalize today's date to midnight to ensure accurate day math
    DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    // Filter the orders first
    var filtered = smController.activeOrders.where((order) {
      String status = (order.status).toLowerCase();
      if (safeStatuses.contains(status)) return false;

      DateTime cleanDeadline = DateTime(order.deliveryDate.year, order.deliveryDate.month, order.deliveryDate.day);
      int daysLeft = cleanDeadline.difference(today).inDays;

      return daysLeft <= 3;
    }).toList();

    // Sort the list so the lowest daysLeft (most overdue) appears FIRST
    filtered.sort((a, b) {
      DateTime aDeadline = DateTime(a.deliveryDate.year, a.deliveryDate.month, a.deliveryDate.day);
      DateTime bDeadline = DateTime(b.deliveryDate.year, b.deliveryDate.month, b.deliveryDate.day);

      int aDaysLeft = aDeadline.difference(today).inDays;
      int bDaysLeft = bDeadline.difference(today).inDays;

      return aDaysLeft.compareTo(bDaysLeft);
    });

    return filtered;
  }

  // 3. ✅ GET PRE-STITCHING QUEUE (Strictly Before Stitching)
  List<OrderModel> get notStitchedOrders {
    // Explicitly define what counts as "Pre-Stitching"
    final preStitchingStatuses = [
      'approved', 'cutting', 'printing', 'printed'
    ];

    return smController.activeOrders.where((order) {
      return preStitchingStatuses.contains(order.status.toLowerCase());
    }).toList();
  }

  // 4. ✅ GET TOTAL UNITS IN PRE-STITCHING QUEUE
  int get totalNotStitchedUnits {
    return notStitchedOrders.fold(0, (sum, order) => sum + order.quantity);
  }
}