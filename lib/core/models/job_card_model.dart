import 'package:cloud_firestore/cloud_firestore.dart';

class JobCardModel {
  final String id; // Normalized Job Card Number
  final String jobCardNumber;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  JobCardModel({
    required this.id,
    required this.jobCardNumber,
    required this.name,
    this.createdAt,
    this.updatedAt,
  });

  factory JobCardModel.fromMap(Map<String, dynamic> map, String docId) {
    return JobCardModel(
      id: docId,
      jobCardNumber: map['jobCardNumber'] ?? docId,
      name: map['name'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jobCardNumber': jobCardNumber,
      'name': name,
      'searchKey': '${jobCardNumber.toLowerCase()} ${name.toLowerCase()}',
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
