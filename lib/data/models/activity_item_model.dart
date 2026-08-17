// ignore_for_file: non_const_argument_for_const_parameter

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
    final data = snapshot is Map<String, dynamic>
        ? snapshot
        : (snapshot.data != null ? snapshot.data() as Map<String, dynamic> : <String, dynamic>{});

    final int code = (data['icon_code'] ?? data['iconCode'] ?? 58835) is int
        ? (data['icon_code'] ?? data['iconCode'] ?? 58835) as int
        : int.tryParse((data['icon_code'] ?? data['iconCode']).toString()) ?? 58835;

    final int colorVal = (data['color_value'] ?? data['colorValue'] ?? 0xFF2196F3) is int
        ? (data['color_value'] ?? data['colorValue'] ?? 0xFF2196F3) as int
        : int.tryParse((data['color_value'] ?? data['colorValue']).toString()) ?? 0xFF2196F3;

    return ActivityItem(
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      time: data['time'] is String
          ? (DateTime.tryParse(data['time']) ?? DateTime.now())
          : (data['time'] is DateTime ? data['time'] as DateTime : DateTime.now()),
      icon: IconData(code, fontFamily: 'MaterialIcons'),
      color: Color(colorVal),
    );
  }
}
