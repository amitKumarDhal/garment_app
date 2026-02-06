import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String? id;
  final String? manualOrderNo;
  final String clientName;
  final String? clientPhone;
  final String? organization;

  // Single Product Fields (Keep these for backward compatibility)
  final String? productCode;
  final String productName;
  final String? productDetails;

  final int quantity;
  final String priority;
  final DateTime orderDate;
  final DateTime deliveryDate;
  final String marketingPersonName;
  final String status;

  final String? sizeDescription;

  final double totalAmount;
  final double gstPercentage;

  // ✅ ADDED: Shipping Charge Field
  final double shippingCharge;

  final String? imageUrl;

  // The List of Products (Required for the new UI)
  final List<Map<String, dynamic>> products;

  OrderModel({
    this.id,
    this.manualOrderNo,
    required this.clientName,
    this.clientPhone,
    this.organization,
    this.productCode,
    required this.productName,
    this.productDetails,
    required this.quantity,
    required this.priority,
    required this.orderDate,
    required this.deliveryDate,
    required this.marketingPersonName,
    this.status = 'Pending',
    required this.totalAmount,
    this.gstPercentage = 0.0,

    this.sizeDescription,

    // ✅ Initialize with default 0.0
    this.shippingCharge = 0.0,

    this.imageUrl,
    this.products = const [],
  });

  /// --- Convert Model to JSON Map for Firestore Storage ---
  Map<String, dynamic> toJson() {
    return {
      "manualOrderNo": manualOrderNo,
      "clientName": clientName,
      "clientPhone": clientPhone,
      "organization": organization,
      "productCode": productCode,
      "productName": productName,
      "productDetails": productDetails,
      "quantity": quantity,
      "priority": priority,
      "orderDate": orderDate,
      "deliveryDate": deliveryDate,
      "marketingPersonName": marketingPersonName,
      "status": status,
      "totalAmount": totalAmount,
      "gstPercentage": gstPercentage,

      "sizeDescription": sizeDescription,

      // ✅ Save shipping charge to Firestore
      "shippingCharge": shippingCharge,

      "imageUrl": imageUrl,
      "createdAt": FieldValue.serverTimestamp(),
      "products": products,
    };
  }

  /// --- Create Model from Firestore Document Snapshot ---
  factory OrderModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (data == null) {
      throw Exception("Document ${document.id} is empty!");
    }

    // SMART PARSING: Handle both Old (Single) and New (List) Data
    List<Map<String, dynamic>> parsedProducts = [];

    if (data['products'] is List) {
      parsedProducts = List<Map<String, dynamic>>.from(data['products']);
    } else {
      parsedProducts.add({
        'productName': data['productName'] ?? '',
        'qty': _parseInt(data['quantity']),
        'price': _parseDouble(data['totalAmount']),
        'total': _parseDouble(data['totalAmount']),
      });
    }

    return OrderModel(
      id: document.id,
      manualOrderNo: data['manualOrderNo'] ?? '',
      clientName: data['clientName'] ?? 'Unknown Client',
      clientPhone: data['clientPhone'] ?? '',
      organization: data['organization'] ?? '',
      productCode: data['productCode'] ?? '',
      productName: data['productName'] ?? '',
      productDetails: data['productDetails'] ?? '',

      quantity: _parseInt(data['quantity']),
      priority: data['priority'] ?? 'Medium',

      orderDate: _parseTimestamp(data['orderDate']),
      deliveryDate: _parseTimestamp(data['deliveryDate']),

      marketingPersonName: data['marketingPersonName'] ?? 'Unknown Agent',
      status: data['status'] ?? 'Pending',

      totalAmount: _parseDouble(data['totalAmount']),
      gstPercentage: _parseDouble(data['gstPercentage']),

      sizeDescription: data['sizeDescription'] ?? '',

      // ✅ Parse shipping charge safely
      shippingCharge: _parseDouble(data['shippingCharge']),

      imageUrl: data['imageUrl'] ?? '',
      products: parsedProducts,
    );
  }

  /// --- HELPER FUNCTIONS ---
  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
