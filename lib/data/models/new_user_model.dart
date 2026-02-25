import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Convert to JSON for Firestore
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
      'createdAt': FieldValue.serverTimestamp(), // Use Server Timestamp
    };
  }

  // Create from Firestore Snapshot
  factory UserModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data()!;
    return UserModel(
      id: document.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      employeeId: data['employeeId'] ?? '',
      role: data['role'] ?? 'Worker',
      status: data['status'] ?? 'Pending',
      unitApproved: data['unitApproved'] ?? false,
      shiftApproved: data['shiftApproved'] ?? false,
      adminApproved: data['adminApproved'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
