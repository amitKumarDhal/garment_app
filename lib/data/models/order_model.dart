import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String? id;
  final String? manualOrderNo;
  final String clientName;
  final String? clientPhone;
  final String? organization;

  // ✅ 1. ADDED: New Fields for Sorting & filtering
  final DateTime? createdAt;
  final DateTime? updatedAt; // <--- ✅ ADDED THIS TO TRACK EDITS
  final String? marketingPersonId;

  // ✅ ADDED: Address Field
  final String? clientAddress;

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

  // ✅ ADDED: Financial Fields
  final double shippingCharge;
  final double advanceAmount;
  final double balanceDue;

  final String? imageUrl;

  // The List of Products (Required for the new UI)
  final List<Map<String, dynamic>> products;

  OrderModel({
    this.id,
    this.manualOrderNo,
    required this.clientName,
    this.clientPhone,
    this.organization,
    this.clientAddress,
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

    this.createdAt,
    this.updatedAt, // <--- ✅ ADDED TO CONSTRUCTOR
    this.marketingPersonId,

    this.shippingCharge = 0.0,
    this.advanceAmount = 0.0,
    this.balanceDue = 0.0,

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

      // ✅ Save Address
      "clientAddress": clientAddress,

      // ✅ Save to Firestore
      "createdAt": createdAt ?? FieldValue.serverTimestamp(),
      "updatedAt": updatedAt, // <--- ✅ SAVE THIS (Controller handles value)
      "marketingPersonId": marketingPersonId,

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

      // ✅ Save Financials
      "shippingCharge": shippingCharge,
      "advanceAmount": advanceAmount,
      "balanceDue": balanceDue,

      "imageUrl": imageUrl,
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

    // Safe integers and doubles for calculation
    int qty = _parseInt(data['quantity']);
    double total = _parseDouble(data['totalAmount']);

    if (data['products'] is List) {
      parsedProducts = List<Map<String, dynamic>>.from(data['products']);
    } else {
      // ✅ FIXED LOGIC HERE:
      // If converting old data, calculate Unit Price correctly.
      // Old way: Price = Total. (Wrong if Qty > 1)
      // New way: Price = Total / Qty.
      double unitPrice = (qty > 0) ? (total / qty) : 0.0;

      parsedProducts.add({
        'productName': data['productName'] ?? '',
        'qty': qty,
        'price': unitPrice, // <--- Corrected
        'total': total,
      });
    }

    return OrderModel(
      id: document.id,
      manualOrderNo: data['manualOrderNo'] ?? '',
      clientName: data['clientName'] ?? 'Unknown Client',
      clientPhone: data['clientPhone'] ?? '',
      organization: data['organization'] ?? '',

      // ✅ Parse Address
      clientAddress: data['clientAddress'] ?? '',

      productCode: data['productCode'] ?? '',
      productName: data['productName'] ?? '',
      productDetails: data['productDetails'] ?? '',

      quantity: qty,
      priority: data['priority'] ?? 'Medium',

      // ✅ Read from Firestore (Nullable timestamps)
      createdAt: _parseTimestampNullable(data['createdAt']),
      updatedAt: _parseTimestampNullable(
        data['updatedAt'],
      ), // <--- ✅ PARSE THIS

      marketingPersonId: data['marketingPersonId'],

      // ✅ Required Dates (Non-nullable, fallback to now())
      orderDate: _parseTimestamp(data['orderDate']),
      deliveryDate: _parseTimestamp(data['deliveryDate']),

      marketingPersonName: data['marketingPersonName'] ?? 'Unknown Agent',
      status: data['status'] ?? 'Pending',

      totalAmount: total,
      gstPercentage: _parseDouble(data['gstPercentage']),

      sizeDescription: data['sizeDescription'] ?? '',

      // ✅ Parse Financials Safely
      shippingCharge: _parseDouble(data['shippingCharge']),
      advanceAmount: _parseDouble(data['advanceAmount']),
      balanceDue: _parseDouble(data['balanceDue']),

      imageUrl: data['imageUrl'] ?? '',
      products: parsedProducts,
    );
  }

  /// --- HELPER FUNCTIONS ---

  // 1. For REQUIRED Dates (Never returns null)
  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  // 2. ✅ For OPTIONAL Dates (Can return null)
  static DateTime? _parseTimestampNullable(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
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
