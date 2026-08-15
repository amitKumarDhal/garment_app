
class PrintingModel {
  final String? id;
  final String styleNo;
  final int receivedFromCutting;
  final Map<String, int> damagedQuantities;
  final int totalDamaged;
  final int netGoodPieces;
  final DateTime timestamp;

  PrintingModel({
    this.id,
    required this.styleNo,
    required this.receivedFromCutting,
    required this.damagedQuantities,
    required this.totalDamaged,
    required this.netGoodPieces,
    required this.timestamp,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() => {
    "styleNo": styleNo,
    "receivedFromCutting": receivedFromCutting,
    "damagedQuantities": damagedQuantities,
    "totalDamaged": totalDamaged,
    "netGoodPieces": netGoodPieces,
    "timestamp": DateTime.now().toIso8601String(),
    "status": "Printing Completed",
  };

  // Create Model from Map / Snapshot
  factory PrintingModel.fromSnapshot(dynamic doc) {
    final data = doc is Map<String, dynamic> ? doc : (doc.data() as Map<String, dynamic>);
    final idVal = doc is Map<String, dynamic> ? doc['id']?.toString() : doc.id;
    return PrintingModel(
      id: idVal,
      styleNo: data['styleNo'] ?? '',
      receivedFromCutting: data['receivedFromCutting'] ?? 0,
      damagedQuantities: Map<String, int>.from(data['damagedQuantities'] ?? {}),
      totalDamaged: data['totalDamaged'] ?? 0,
      netGoodPieces: data['netGoodPieces'] ?? 0,
      timestamp: data['timestamp'] is String ? (DateTime.tryParse(data['timestamp']) ?? DateTime.now()) : DateTime.now(),
    );
  }
}
