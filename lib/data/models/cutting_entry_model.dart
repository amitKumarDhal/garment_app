import 'package:cloud_firestore/cloud_firestore.dart';

class CuttingEntryModel {
  final String? id;
  final String styleNo; // Changed from orderId to match your form
  final String lotNo; // Batch number
  final String fabricType; // Linked to Inventory
  final double consumption; // Meters per piece
  final double totalFabricUsed; // Total meters deducted
  final Map<String, int> sizes; // S, M, L, XL breakdown
  final int totalQuantity; // Total pieces cut
  final DateTime entryDate;
  final String status;

  CuttingEntryModel({
    this.id,
    required this.styleNo,
    required this.lotNo,
    required this.fabricType,
    required this.consumption,
    required this.totalFabricUsed,
    required this.sizes,
    required this.totalQuantity,
    required this.entryDate,
    required this.status,
  });

  // Convert to JSON (for Firestore Write)
  Map<String, dynamic> toJson() => {
    "styleNo": styleNo,
    "lotNo": lotNo,
    "fabricType": fabricType,
    "consumption": consumption,
    "totalFabricUsed": totalFabricUsed,
    "sizes": sizes,
    "totalQuantity": totalQuantity,
    "entryDate": entryDate,
    "status": status,
    "timestamp": FieldValue.serverTimestamp(),
  };

  // Create from Snapshot (for Firestore Read)
  factory CuttingEntryModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return CuttingEntryModel(
      id: snapshot.id,
      styleNo: data['styleNo'] ?? '',
      lotNo: data['lotNo'] ?? '',
      fabricType: data['fabricType'] ?? '',
      consumption: (data['consumption'] as num?)?.toDouble() ?? 0.0,
      totalFabricUsed: (data['totalFabricUsed'] as num?)?.toDouble() ?? 0.0,
      sizes: Map<String, int>.from(data['sizes'] ?? {}),
      totalQuantity: data['totalQuantity'] ?? 0,
      entryDate: (data['entryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'Pending',
    );
  }
}
