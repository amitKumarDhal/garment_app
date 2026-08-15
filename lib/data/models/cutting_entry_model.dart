
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

  // Convert to JSON
  Map<String, dynamic> toJson() => {
    "styleNo": styleNo,
    "lotNo": lotNo,
    "fabricType": fabricType,
    "consumption": consumption,
    "totalFabricUsed": totalFabricUsed,
    "sizes": sizes,
    "totalQuantity": totalQuantity,
    "entryDate": entryDate.toIso8601String(),
    "status": status,
    "timestamp": DateTime.now().toIso8601String(),
  };

  // Create from Map / Snapshot
  factory CuttingEntryModel.fromSnapshot(dynamic snapshot) {
    final data = snapshot is Map<String, dynamic> ? snapshot : (snapshot.data() as Map<String, dynamic>);
    final idVal = snapshot is Map<String, dynamic> ? snapshot['id']?.toString() : snapshot.id;
    return CuttingEntryModel(
      id: idVal,
      styleNo: data['styleNo'] ?? '',
      lotNo: data['lotNo'] ?? '',
      fabricType: data['fabricType'] ?? '',
      consumption: (data['consumption'] as num?)?.toDouble() ?? 0.0,
      totalFabricUsed: (data['totalFabricUsed'] as num?)?.toDouble() ?? 0.0,
      sizes: Map<String, int>.from(data['sizes'] ?? {}),
      totalQuantity: data['totalQuantity'] ?? 0,
      entryDate: data['entryDate'] is String ? (DateTime.tryParse(data['entryDate']) ?? DateTime.now()) : DateTime.now(),
      status: data['status'] ?? 'Pending',
    );
  }
}
