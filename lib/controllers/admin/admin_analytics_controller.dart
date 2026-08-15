import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/api_service.dart';

class AdminAnalyticsController extends GetxController {
  var analyticsData = <String, dynamic>{}.obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAnalytics();
  }

  Future<void> fetchAnalytics() async {
    try {
      isLoading.value = true;
      final res = await ApiService.get('/analytics/dashboard');
      if (res['success'] == true && res['data'] != null) {
        analyticsData.value = Map<String, dynamic>.from(res['data']);
      }
    } catch (e) {
      debugPrint("Fetch Analytics Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  var selectedTab = 'Overview'.obs;
  var selectedRegionSort = 'Revenue'.obs;
  var selectedTimeframe = 'All Time'.obs;
  var selectedSubFilter = 'Overall'.obs;

  var totalOrders = 0.obs;
  var totalRevenue = 0.0.obs;
  var averageOrderValue = 0.0.obs;
  var regionalPerformance = <Map<String, dynamic>>[].obs;

  void switchTab(String tab) => selectedTab.value = tab;
  void setRegionSort(String sort) => selectedRegionSort.value = sort;
  Future<void> fetchAnalyticsData({bool showSpinner = true}) async => await fetchAnalytics();

  List<String> get timeframes => ['All Time', 'This Month', 'Last Month', 'Custom'];
  void setTimeframe(String tf) => selectedTimeframe.value = tf;

  List<String> get currentSubOptions => ['Overall', 'By Category', 'By Region'];
  void setSubFilter(String sub) => selectedSubFilter.value = sub;
}