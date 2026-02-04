import 'package:flutter/material.dart';
import '../../utils/constants/colors.dart';
import '../floor_management/marketing_upload_screen.dart';

class SalesOrdersScreen extends StatelessWidget {
  const SalesOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : TColors.light,
      appBar: AppBar(
        title: const Text("New Order Entry"),
        centerTitle: true,
        backgroundColor: isDark ? TColors.dark : Colors.white,
        elevation: 0,
        // ✅ Tabs and History are removed.
      ),
      // ✅ Body is now directly the Upload Form
      body: const MarketingUploadScreen(),
    );
  }
}
