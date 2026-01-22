import 'package:cloud_firestore/cloud_firestore.dart';

class StitchingModel {
  final String? id;
  final String workerName;
  final String styleNo;
  final String operationType;
  final int assignedQty;
  final int completedQty;
  final int rejectedQty;
  final double efficiency;
  final DateTime timestamp;

  StitchingModel({
    this.id,
    required this.workerName,
    required this.styleNo,
    required this.operationType,
    required this.assignedQty,
    required this.completedQty,
    required this.rejectedQty,
    required this.efficiency,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    "workerName": workerName,
    "styleNo": styleNo,
    "operationType": operationType,
    "assignedQty": assignedQty,
    "completedQty": completedQty,
    "rejectedQty": rejectedQty,
    "efficiency": efficiency,
    "timestamp": FieldValue.serverTimestamp(),
    "status": "Stitching Completed",
  };
}
