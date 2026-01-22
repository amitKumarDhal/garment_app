import 'package:cloud_firestore/cloud_firestore.dart';

class CuttingEntryModel {
  final String? id;
  final String orderId; // Link back to the original Marketing Order
  final String clientName;
  final int piecesCut;
  final int fabricWastage; // Percentage or meters
  final String supervisorName;
  final DateTime entryDate;

  CuttingEntryModel({
    this.id,
    required this.orderId,
    required this.clientName,
    required this.piecesCut,
    required this.fabricWastage,
    required this.supervisorName,
    required this.entryDate,
  });

  Map<String, dynamic> toJson() => {
    "orderId": orderId,
    "clientName": clientName,
    "piecesCut": piecesCut,
    "fabricWastage": fabricWastage,
    "supervisorName": supervisorName,
    "entryDate": entryDate,
    "timestamp": FieldValue.serverTimestamp(),
  };
}
