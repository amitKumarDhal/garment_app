import 'package:cloud_firestore/cloud_firestore.dart';

class PrintingModel {
  final String? id;
  final String styleNo;
  final int receivedFromCutting;
  final Map<String, int> damagedQuantities;
  final int totalDamaged;
  final int netGoodPieces;
  final DateTime timestamp;

  PrintingModel({
    this.id,
    required this.styleNo,
    required this.receivedFromCutting,
    required this.damagedQuantities,
    required this.totalDamaged,
    required this.netGoodPieces,
    required this.timestamp,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() => {
    "styleNo": styleNo,
    "receivedFromCutting": receivedFromCutting,
    "damagedQuantities": damagedQuantities,
    "totalDamaged": totalDamaged,
    "netGoodPieces": netGoodPieces,
    "timestamp": FieldValue.serverTimestamp(),
    "status": "Printing Completed",
  };

  // Create Model from Firestore Snapshot
  factory PrintingModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return PrintingModel(
      id: doc.id,
      styleNo: data['styleNo'] ?? '',
      receivedFromCutting: data['receivedFromCutting'] ?? 0,
      damagedQuantities: Map<String, int>.from(data['damagedQuantities'] ?? {}),
      totalDamaged: data['totalDamaged'] ?? 0,
      netGoodPieces: data['netGoodPieces'] ?? 0,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}
