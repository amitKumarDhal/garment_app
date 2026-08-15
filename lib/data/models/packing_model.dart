
class PackingModel {
  String? id; // Firestore Document ID
  final String cartonNo;
  final String styleNo;
  final String category;
  final int totalPieces;
  final Map<String, int> breakdown;
  final DateTime? timestamp;

  PackingModel({
    this.id,
    required this.cartonNo,
    required this.styleNo,
    required this.category,
    required this.totalPieces,
    required this.breakdown,
    this.timestamp,
  });

  // 1. Convert Map / Snapshot to Dart Object
  factory PackingModel.fromSnapshot(dynamic snapshot) {
    final data = snapshot is Map<String, dynamic> ? snapshot : (snapshot.data() as Map<String, dynamic>);
    final idVal = snapshot is Map<String, dynamic> ? snapshot['id']?.toString() : snapshot.id;

    // Handle the nested breakdown map safely
    Map<String, int> safeBreakdown = {};
    if (data['breakdown'] != null) {
      Map<String, dynamic> rawMap = data['breakdown'];
      rawMap.forEach((key, value) {
        safeBreakdown[key] = int.tryParse(value.toString()) ?? 0;
      });
    }

    return PackingModel(
      id: idVal,
      cartonNo: data['cartonNo'] ?? '',
      styleNo: data['styleNo'] ?? '',
      category: data['category'] ?? 'M',
      totalPieces: data['totalPieces'] ?? 0,
      breakdown: safeBreakdown,
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] is String
              ? DateTime.tryParse(data['timestamp'].toString())
              : null)
          : null,
    );
  }

  // 2. Convert Dart Object to Map (for Uploading)
  Map<String, dynamic> toJson() {
    return {
      "cartonNo": cartonNo,
      "styleNo": styleNo,
      "category": category,
      "totalPieces": totalPieces,
      "breakdown": breakdown,
      "timestamp": DateTime.now().toIso8601String(),
      "status": "Packed",
    };
  }
}
