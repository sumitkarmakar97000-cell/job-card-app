import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String userId;
  final String userName;
  final String role; // 'admin' or 'user'
  final bool isActive;
  final int selectedCount;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.userId,
    required this.userName,
    required this.role,
    required this.isActive,
    this.selectedCount = 0,
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      uid: docId,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      role: map['role'] ?? 'user',
      isActive: map['isActive'] ?? true,
      selectedCount: (map['selectedCount'] ?? 0).toInt(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'userId': userId,
      'userName': userName,
      'role': role,
      'isActive': isActive,
      'selectedCount': selectedCount,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
