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
  final String? mockupUrl;

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

  final bool mockupDone;
  final String? mockupApprovedBy;
  final DateTime? mockupDoneAt;

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
    this.mockupDone = false,
    this.mockupApprovedBy,
    this.mockupDoneAt,
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
      "createdAt": createdAt ?? DateTime.now().toIso8601String(),
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

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel.fromSnapshot(json);

  factory OrderModel.fromSnapshot(dynamic document) {
    final Map<String, dynamic> data = document is Map<String, dynamic>
        ? document
        : (document is Map
            ? Map<String, dynamic>.from(document)
            : (document?.data != null ? document.data() as Map<String, dynamic> : <String, dynamic>{}));

    // SMART PARSING
    List<Map<String, dynamic>> parsedProducts = [];
    int qty = _parseInt(data['quantity'] ?? data['qty']);
    double total = _parseDouble(data['total_amount'] ?? data['totalAmount'] ?? data['total']);

    if (data['order_items'] != null && data['order_items'] is List && (data['order_items'] as List).isNotEmpty) {
      parsedProducts = (data['order_items'] as List).map((item) {
        final m = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
        return {
          'id': m['id']?.toString() ?? '',
          'productCode': m['product_code'] ?? m['productCode'] ?? '',
          'productName': m['product_name'] ?? m['productName'] ?? '',
          'sizeDescription': m['size_description'] ?? m['sizeDescription'] ?? '',
          'qty': _parseInt(m['qty'] ?? m['quantity']),
          'price': _parseDouble(m['price']),
          'gstPercentage': _parseDouble(m['gst_percentage'] ?? m['gstPercentage']),
          'total': _parseDouble(m['total']),
          'neckType': m['neck_type'] ?? m['neckType'] ?? 'Not Specified',
          'productType': m['product_type'] ?? m['productType'] ?? 'Not Specified',
          'color': m['color'] ?? 'Not Specified',
          'fabricType': m['fabric_type'] ?? m['fabricType'] ?? 'Not Specified',
        };
      }).toList();
    } else if (data['products'] != null && data['products'] is List && (data['products'] as List).isNotEmpty) {
      parsedProducts = (data['products'] as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } else {
      // Legacy conversion
      double unitPrice = (qty > 0) ? (total / qty) : 0.0;
      parsedProducts.add({
        'productCode': data['product_code'] ?? data['productCode'] ?? '',
        'productName': data['product_name'] ?? data['productName'] ?? '',
        'sizeDescription': data['size_description'] ?? data['sizeDescription'] ?? '',
        'qty': qty,
        'price': unitPrice,
        'gstPercentage': _parseDouble(data['gst_percentage'] ?? data['gstPercentage']),
        'total': total,
        'neckType': data['neck_type'] ?? data['neckType'] ?? 'Not Specified',
        'productType': data['product_type'] ?? data['productType'] ?? 'Not Specified',
        'color': data['color'] ?? 'Not Specified',
        'fabricType': data['fabric_type'] ?? data['fabricType'] ?? 'Not Specified',
      });
    }

    String? docId;
    if (data['id'] != null) {
      docId = data['id'].toString();
    } else {
      try {
        docId = document?.id?.toString();
      } catch (_) {
        docId = null;
      }
    }

    return OrderModel(
      id: docId,
      manualOrderNo: data['manual_order_no'] ?? data['manualOrderNo'] ?? '',
      clientName: data['client_name'] ?? data['clientName'] ?? 'Unknown Client',
      clientPhone: data['client_phone'] ?? data['clientPhone'] ?? '',
      organization: data['organization'] ?? '',
      clientAddress: data['client_address'] ?? data['clientAddress'] ?? '',
      clientGstNumber: data['client_gst_number'] ?? data['clientGstNumber'] ?? '',
      pincode: data['pincode']?.toString() ?? '',
      state: data['state']?.toString() ?? '',
      productCode: data['product_code'] ?? data['productCode'] ?? '',
      productName: data['product_name'] ?? data['productName'] ?? '',
      productDetails: data['product_details'] ?? data['productDetails'] ?? '',
      quantity: qty,
      priority: data['priority'] ?? 'Medium',
      createdAt: _parseTimestampNullable(data['created_at'] ?? data['createdAt']),
      updatedAt: _parseTimestampNullable(data['updated_at'] ?? data['updatedAt']),
      lastUpdatedBy: data['last_updated_by'] ?? data['lastUpdatedBy'],
      marketingPersonId: data['marketing_person_id'] ?? data['marketingPersonId'],
      orderDate: _parseTimestamp(data['order_date'] ?? data['orderDate']),
      deliveryDate: _parseTimestamp(data['delivery_date'] ?? data['deliveryDate']),
      marketingPersonName: data['marketing_person_name'] ?? data['marketingPersonName'] ?? 'Unknown Agent',
      status: data['status'] ?? 'Pending',
      isDeleted: data['is_deleted'] ?? data['isDeleted'] ?? false,
      totalAmount: total,
      gstPercentage: _parseDouble(data['gst_percentage'] ?? data['gstPercentage']),
      sizeDescription: data['size_description'] ?? data['sizeDescription'] ?? '',
      shippingCharge: _parseDouble(data['shipping_charge'] ?? data['shippingCharge']),
      advanceAmount: _parseDouble(data['advance_amount'] ?? data['advanceAmount']),
      balanceDue: _parseDouble(data['balance_due'] ?? data['balanceDue']),
      imageUrl: data['image_url'] ?? data['imageUrl'] ?? '',
      localImagePath: data['local_image_path'] ?? data['localImagePath'] ?? '',
      mockupUrl: data['mockup_url'] ?? data['mockupUrl'] ?? data['design_mockup_url'] ?? data['designMockupUrl'] ?? '',
      products: parsedProducts,

      // FETCH MARGIN DATA SAFELY
      marginNumber: _parseInt(data['margin_number'] ?? data['marginNumber']),
      effectiveRevenue: _parseDouble(data['effective_revenue'] ?? data['effectiveRevenue']),

      // FETCH DELETION FLAG SAFELY
      isDeleteRequested: data['is_delete_requested'] ?? data['isDeleteRequested'] ?? false,

      // FETCH PAYMENT HISTORY SAFELY
      paymentHistory: data['payment_history'] ?? data['paymentHistory'] ?? [],

      // FETCH STAGE HISTORY SAFELY
      stageHistory: data['stage_history'] ?? data['stageHistory'] ?? [],

      neckType: data['neck_type'] ?? data['neckType'] ?? 'Not Specified',
      productType: data['product_type'] ?? data['productType'] ?? 'Not Specified',
      color: data['color'] ?? 'Not Specified',
      mockupDone: data['mockup_done'] ?? data['mockupDone'] ?? false,
      mockupApprovedBy: data['mockup_approved_by'] ?? data['mockupApprovedBy'] ?? '',
      mockupDoneAt: _parseTimestampNullable(data['mockup_done_at'] ?? data['mockupDoneAt']),
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static DateTime? _parseTimestampNullable(dynamic value) {
    if (value is DateTime) return value;
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