import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yoobbel/controllers/admin/worker_report_controller.dart';

class DailyWorkLogScreen extends StatelessWidget {
  const DailyWorkLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WorkerReportController());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Work Report"),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // Summary Header
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.teal.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Today's Total Output:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "450 Pieces",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // List of Work Entries
          Expanded(
            child: Obx(
              () => ListView.builder(
                itemCount: controller.dailyLogs.length,
                itemBuilder: (context, index) {
                  final log = controller.dailyLogs[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 5,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(log['name'].toString()[0]),
                      ),
                      title: Text("${log['name']} - ${log['op']}"),
                      subtitle: Text(
                        "Style: ${log['style']} | Time: ${log['time']}",
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${log['qty']}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const Text("Pcs", style: TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
