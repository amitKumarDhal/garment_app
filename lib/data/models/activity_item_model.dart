import 'package:flutter/material.dart';

class ActivityItem {
  final String title;
  final String subtitle;
  final DateTime time;
  final IconData icon;
  final Color color;

  ActivityItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
  });

  factory ActivityItem.fromSnapshot(dynamic snapshot) {
    final data = snapshot is Map<String, dynamic> ? snapshot : (snapshot.data != null ? snapshot.data() as Map<String, dynamic> : <String, dynamic>{});

    return ActivityItem(
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      time: data['time'] is String
          ? (DateTime.tryParse(data['time']) ?? DateTime.now())
          : (data['time'] is DateTime ? data['time'] as DateTime : DateTime.now()),
      icon: IconData(data['iconCode'] ?? 58835, fontFamily: 'MaterialIcons'),
      color: Color(data['colorValue'] ?? 0xFF2196F3),
    );
  }
}
