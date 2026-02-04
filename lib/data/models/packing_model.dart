import 'package:cloud_firestore/cloud_firestore.dart';

class PackingModel {
  String? id; // Firestore Document ID
  final String cartonNo;
  final String styleNo;
  final String category;
  final int totalPieces;
  final Map<String, int> breakdown;
  final DateTime? timestamp;

  PackingModel({
    this.id,
    required this.cartonNo,
    required this.styleNo,
    required this.category,
    required this.totalPieces,
    required this.breakdown,
    this.timestamp,
  });

  // 1. Convert Firestore Document to Dart Object
  factory PackingModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data()!;

    // Handle the nested breakdown map safely
    Map<String, int> safeBreakdown = {};
    if (data['breakdown'] != null) {
      Map<String, dynamic> rawMap = data['breakdown'];
      rawMap.forEach((key, value) {
        safeBreakdown[key] = int.tryParse(value.toString()) ?? 0;
      });
    }

    return PackingModel(
      id: document.id,
      cartonNo: data['cartonNo'] ?? '',
      styleNo: data['styleNo'] ?? '',
      category: data['category'] ?? 'M',
      totalPieces: data['totalPieces'] ?? 0,
      breakdown: safeBreakdown,
      // Handle Firestore Timestamp conversion
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : null,
    );
  }

  // 2. Convert Dart Object to Map (for Uploading)
  Map<String, dynamic> toJson() {
    return {
      "cartonNo": cartonNo,
      "styleNo": styleNo,
      "category": category,
      "totalPieces": totalPieces,
      "breakdown": breakdown,
      "timestamp":
          FieldValue.serverTimestamp(), // Always use server time on create
      "status": "Packed",
    };
  }
}
