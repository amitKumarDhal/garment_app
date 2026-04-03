import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OrderModel {
  final String? id;
  final String? manualOrderNo;
  final String clientName;
  final String? clientPhone;
  final String? organization;
  final String? clientAddress;

  // ✅ NEW: GST NUMBER FIELD
  final String? clientGstNumber;

  // ✅ LOCATION FIELDS
  final String? pincode;
  final String? state;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? lastUpdatedBy;
  final String? marketingPersonId;

  // ✅ PRODUCT SPECIFICS (Root level for quick access)
  final String? neckType;
  final String? productType;
  final String? color; // ✅ ADDED COLOR FIELD

  // Single Product Fields (Maintained for Legacy backward compatibility)
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

  // Financial Fields
  final double shippingCharge;
  final double advanceAmount;
  final double balanceDue;

  // Image Paths
  final String? imageUrl;
  final String? localImagePath;
  final String? mockupUrl; // FOR CLOUDINARY MOCKUPS

  // THE DYNAMIC MULTI-ITEM LIST
  final List<Map<String, dynamic>> products;

  // INTERNAL MARGIN FIELDS
  final int marginNumber;
  final double effectiveRevenue;

  // FLAG FOR DELETION WORKFLOW
  final bool isDeleteRequested;
  final bool isDeleted;

  // PAYMENT HISTORY LOG
  final List<dynamic> paymentHistory;

  // STAGE UPDATE HISTORY LOG
  final List<dynamic> stageHistory;

  // Automatically formats the deliveryDate into a readable deadline string
  String get deadline => DateFormat('dd-MM-yyyy').format(deliveryDate);

  OrderModel({
    this.id,
    this.manualOrderNo,
    required this.clientName,
    this.clientPhone,
    this.organization,
    this.clientAddress,
    this.clientGstNumber, // ✅ ADDED
    this.pincode,
    this.state,
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
    this.updatedAt,
    this.lastUpdatedBy,
    this.marketingPersonId,
    this.shippingCharge = 0.0,
    this.advanceAmount = 0.0,
    this.balanceDue = 0.0,
    this.imageUrl,
    this.localImagePath,
    this.mockupUrl,
    this.products = const [],
    this.marginNumber = 0,
    this.effectiveRevenue = 0.0,
    this.isDeleteRequested = false,
    this.isDeleted = false,
    this.paymentHistory = const [],
    this.stageHistory = const [],
    this.neckType = 'Not Specified',
    this.productType = 'Not Specified',
    this.color = 'Not Specified',
  });

  Map<String, dynamic> toJson() {
    return {
      "manualOrderNo": manualOrderNo,
      "clientName": clientName,
      "clientPhone": clientPhone,
      "organization": organization,
      "clientAddress": clientAddress,
      "clientGstNumber": clientGstNumber, // ✅ ADDED
      "pincode": pincode,
      "state": state,
      "createdAt": createdAt ?? FieldValue.serverTimestamp(),
      "updatedAt": updatedAt,
      "lastUpdatedBy": lastUpdatedBy,
      "marketingPersonId": marketingPersonId,

      // Root legacy fields
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

      "shippingCharge": shippingCharge,
      "advanceAmount": advanceAmount,
      "balanceDue": balanceDue,
      "imageUrl": imageUrl,
      "localImagePath": localImagePath,
      "mockupUrl": mockupUrl,

      // Save the dynamic array
      "products": products,

      // SAVE MARGIN DATA
      "marginNumber": marginNumber,
      "effectiveRevenue": effectiveRevenue,

      // SAVE DELETION FLAG
      "isDeleteRequested": isDeleteRequested,
      "isDeleted": isDeleted,

      // SAVE PAYMENT HISTORY
      "paymentHistory": paymentHistory,

      // SAVE STAGE HISTORY
      "stageHistory": stageHistory,

      "neckType": neckType,
      "productType": productType,
      "color": color,
    };
  }

  factory OrderModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    if (data == null) throw Exception("Document ${document.id} is empty!");

    // SMART PARSING
    List<Map<String, dynamic>> parsedProducts = [];
    int qty = _parseInt(data['quantity']);
    double total = _parseDouble(data['totalAmount']);

    if (data['products'] != null && data['products'] is List && (data['products'] as List).isNotEmpty) {
      // Ultra-safe mapping prevents Map<dynamic, dynamic> cast crashes
      parsedProducts = (data['products'] as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } else {
      // Legacy conversion
      double unitPrice = (qty > 0) ? (total / qty) : 0.0;
      parsedProducts.add({
        'productCode': data['productCode'] ?? '',
        'productName': data['productName'] ?? '',
        'sizeDescription': data['sizeDescription'] ?? '',
        'qty': qty,
        'price': unitPrice,
        'gstPercentage': _parseDouble(data['gstPercentage']),
        'total': total,
        'neckType': data['neckType'] ?? 'Not Specified',
        'productType': data['productType'] ?? 'Not Specified',
        'color': data['color'] ?? 'Not Specified',
      });
    }

    return OrderModel(
      id: document.id,
      manualOrderNo: data['manualOrderNo'] ?? '',
      clientName: data['clientName'] ?? 'Unknown Client',
      clientPhone: data['clientPhone'] ?? '',
      organization: data['organization'] ?? '',
      clientAddress: data['clientAddress'] ?? '',
      clientGstNumber: data['clientGstNumber'] ?? '', // ✅ ADDED
      pincode: data['pincode']?.toString() ?? '',
      state: data['state']?.toString() ?? '',
      productCode: data['productCode'] ?? '',
      productName: data['productName'] ?? '',
      productDetails: data['productDetails'] ?? '',
      quantity: qty,
      priority: data['priority'] ?? 'Medium',
      createdAt: _parseTimestampNullable(data['createdAt']),
      updatedAt: _parseTimestampNullable(data['updatedAt']),
      lastUpdatedBy: data['lastUpdatedBy'],
      marketingPersonId: data['marketingPersonId'],
      orderDate: _parseTimestamp(data['orderDate']),
      deliveryDate: _parseTimestamp(data['deliveryDate']),
      marketingPersonName: data['marketingPersonName'] ?? 'Unknown Agent',
      status: data['status'] ?? 'Pending',
      isDeleted: data['isDeleted'] ?? false,
      totalAmount: total,
      gstPercentage: _parseDouble(data['gstPercentage']),
      sizeDescription: data['sizeDescription'] ?? '',
      shippingCharge: _parseDouble(data['shippingCharge']),
      advanceAmount: _parseDouble(data['advanceAmount']),
      balanceDue: _parseDouble(data['balanceDue']),
      imageUrl: data['imageUrl'] ?? '',
      localImagePath: data['localImagePath'] ?? '',

      mockupUrl: data['mockupUrl'] ?? data['designMockupUrl'] ?? '',

      products: parsedProducts,

      // FETCH MARGIN DATA SAFELY
      marginNumber: _parseInt(data['marginNumber']),
      effectiveRevenue: _parseDouble(data['effectiveRevenue']),

      // FETCH DELETION FLAG SAFELY
      isDeleteRequested: data['isDeleteRequested'] ?? false,

      // FETCH PAYMENT HISTORY SAFELY
      paymentHistory: data['paymentHistory'] ?? [],

      // FETCH STAGE HISTORY SAFELY
      stageHistory: data['stageHistory'] ?? [],

      neckType: data['neckType'] ?? 'Not Specified',
      productType: data['productType'] ?? 'Not Specified',
      color: data['color'] ?? 'Not Specified',
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static DateTime? _parseTimestampNullable(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
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
    if (value is String) {
      String clean = value.replaceAll(',', '').replaceAll('₹', '').trim();
      return double.tryParse(clean) ?? 0.0;
    }
    return 0.0;
  }
}