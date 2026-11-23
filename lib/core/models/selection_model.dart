import 'package:cloud_firestore/cloud_firestore.dart';

class SelectionModel {
  final String id; // {uid}_{jobCardNumber}
  final String uid;
  final String userId;
  final String jobCardNumber;
  final String name;
  final DateTime? selectedAt;

  SelectionModel({
    required this.id,
    required this.uid,
    required this.userId,
    required this.jobCardNumber,
    required this.name,
    this.selectedAt,
  });

  factory SelectionModel.fromMap(Map<String, dynamic> map, String docId) {
    return SelectionModel(
      id: docId,
      uid: map['uid'] ?? '',
      userId: map['userId'] ?? '',
      jobCardNumber: map['jobCardNumber'] ?? '',
      name: map['name'] ?? '',
      selectedAt: (map['selectedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'userId': userId,
      'jobCardNumber': jobCardNumber,
      'name': name,
      'selectedAt': FieldValue.serverTimestamp(),
    };
  }
}
