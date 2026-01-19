import 'package:get/get.dart';

class WorkerReportController extends GetxController {
  // Dummy Data representing the daily log
  var dailyLogs = [
    {
      'name': 'Rahul',
      'style': 'TS-101',
      'op': 'Collar',
      'qty': 150,
      'time': '10:30 AM',
    },
    {
      'name': 'Priya',
      'style': 'TS-101',
      'op': 'Sleeve',
      'qty': 200,
      'time': '11:15 AM',
    },
    {
      'name': 'Rahul',
      'style': 'TS-102',
      'op': 'Side Seam',
      'qty': 100,
      'time': '02:00 PM',
    },
  ].obs;

  // Filtered list for a specific worker
  var filteredLogs = [].obs;

  void filterByWorker(String name) {
    filteredLogs.value = dailyLogs.where((log) => log['name'] == name).toList();
  }
}
