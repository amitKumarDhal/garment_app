import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // ✅ ADD THIS: Factory to convert Firestore Document to ActivityItem
  factory ActivityItem.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;

    return ActivityItem(
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      // Read time as Timestamp and convert to DateTime
      time: (data['time'] as Timestamp?)?.toDate() ?? DateTime.now(),
      // Read Icon codePoint (int) and convert back to IconData
      icon: IconData(data['iconCode'] ?? 58835, fontFamily: 'MaterialIcons'),
      // Read Color value (int) and convert back to Color
      color: Color(data['colorValue'] ?? 0xFF2196F3),
    );
  }
}
