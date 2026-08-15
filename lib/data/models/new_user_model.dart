
class UserModel {
  final String id;
  final String name;
  final String email;
  final String employeeId;
  final String role;
  final String status; // 'Pending', 'Approved', 'Rejected'
  final bool unitApproved;
  final bool shiftApproved;
  final bool adminApproved;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.employeeId,
    required this.role,
    required this.status,
    this.unitApproved = false,
    this.shiftApproved = false,
    this.adminApproved = false,
    required this.createdAt,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'employeeId': employeeId,
      'role': role,
      'status': status,
      'unitApproved': unitApproved,
      'shiftApproved': shiftApproved,
      'adminApproved': adminApproved,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from Map / Snapshot
  factory UserModel.fromSnapshot(dynamic snapshot) {
    final Map<String, dynamic> data = snapshot is Map<String, dynamic> ? snapshot : (snapshot.data() as Map<String, dynamic>);
    final String idVal = snapshot is Map<String, dynamic> ? (snapshot['id'] ?? '').toString() : snapshot.id;
    return UserModel(
      id: idVal,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      employeeId: data['employeeId'] ?? '',
      role: data['role'] ?? 'UNIT_SUPERVISOR',
      status: data['status'] ?? 'Pending',
      unitApproved: data['unitApproved'] ?? false,
      shiftApproved: data['shiftApproved'] ?? false,
      adminApproved: data['adminApproved'] ?? false,
      createdAt: data['createdAt'] is String ? (DateTime.tryParse(data['createdAt']) ?? DateTime.now()) : DateTime.now(),
    );
  }
}
