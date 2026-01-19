import 'package:get/get.dart';

class NavigationController extends GetxController {
  // Current index of the bottom nav bar
  final selectedIndex = 0.obs;

  // Function to change index
  void changeIndex(int index) => selectedIndex.value = index;
}
