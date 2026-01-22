import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String? id; // Unique Document ID from Firestore
  final String clientName;
  final String productName;
  final int quantity;
  final String priority; // e.g., Low, Medium, High
  final DateTime orderDate;
  final DateTime deliveryDate;
  final String marketingPersonName;
  final String status; // e.g., Pending, Processing, Completed
  final double totalAmount;

  OrderModel({
    this.id,
    required this.clientName,
    required this.productName,
    required this.quantity,
    required this.priority,
    required this.orderDate,
    required this.deliveryDate,
    required this.marketingPersonName,
    this.status = 'Pending',
    required this.totalAmount,
  });

  /// --- Convert Model to JSON Map for Firestore Storage ---
  Map<String, dynamic> toJson() {
    return {
      "clientName": clientName,
      "productName": productName,
      "quantity": quantity,
      "priority": priority,
      "orderDate": orderDate,
      "deliveryDate": deliveryDate,
      "marketingPersonName": marketingPersonName,
      "status": status,
      "totalAmount": totalAmount,
      "createdAt":
          FieldValue.serverTimestamp(), // Database-side timestamp for sorting
    };
  }

  /// --- Create Model from Firestore Document Snapshot ---
  factory OrderModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data()!;
    return OrderModel(
      id: document.id,
      clientName: data['clientName'] ?? '',
      productName: data['productName'] ?? '',
      quantity: data['quantity'] ?? 0,
      priority: data['priority'] ?? 'Medium',
      // Convert Firestore Timestamp objects back to Dart DateTime objects
      orderDate: (data['orderDate'] as Timestamp).toDate(),
      deliveryDate: (data['deliveryDate'] as Timestamp).toDate(),
      marketingPersonName: data['marketingPersonName'] ?? '',
      status: data['status'] ?? 'Pending',
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
    );
  }
}
