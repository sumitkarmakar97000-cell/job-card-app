import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job_card_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String normalizeDocId(String jobCardNumber) {
    return jobCardNumber.trim().replaceAll('/', '_');
  }

  Future> uploadMasterJobCards(
    List> records,
    void Function(double) onProgress,
  ) async {
    int addedCount = 0;
    int skippedDuplicateCount = 0;

    final existingSnapshot = await _db.collection('job_cards').get();
    final Set<String> existingIds =
        existingSnapshot.docs.map((doc) => doc.id).toSet();

    final List> newRecordsToInsert = [];

    for (var record in records) {
      final cardNo = record['jobCardNumber']!;
      final docId = normalizeDocId(cardNo);

      if (existingIds.contains(docId)) {
        skippedDuplicateCount++;
      } else {
        existingIds.add(docId);
        newRecordsToInsert.add(record);
      }
    }

    const int batchSize = 450;
    final int total = newRecordsToInsert.length;

    for (int i = 0; i < total; i += batchSize) {
      final batch = _db.batch();
      final end = (i + batchSize < total) ? i + batchSize : total;
      final chunk = newRecordsToInsert.sublist(i, end);

      for (var item in chunk) {
        final cardNo = item['jobCardNumber']!;
        final name = item['name']!;
        final docId = normalizeDocId(cardNo);
        final docRef = _db.collection('job_cards').doc(docId);

        batch.set(docRef, {
          'jobCardNumber': cardNo,
          'name': name,
          'searchKey': '${cardNo.toLowerCase()} ${name.toLowerCase()}',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        addedCount++;
      }

      await batch.commit();
      if (total > 0) {
        onProgress(end / total);
      }
    }

    return {
      'added': addedCount,
      'duplicates': skippedDuplicateCount,
    };
  }

  Future<void> saveSingleJobCard(String jobCardNumber, String name, {bool isEdit = false}) async {
    final docId = normalizeDocId(jobCardNumber);
    final docRef = _db.collection('job_cards').doc(docId);

    if (!isEdit) {
      final exists = await docRef.get();
      if (exists.exists) {
        throw Exception('এই Job Card Number ইতিমধ্যে ডাটাবেসে আছে!');
      }
    }

    await docRef.set({
      'jobCardNumber': jobCardNumber.trim(),
      'name': name.trim(),
      'searchKey': '${jobCardNumber.trim().toLowerCase()} ${name.trim().toLowerCase()}',
      if (!isEdit) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteJobCard(String docId) async {
    await _db.collection('job_cards').doc(docId).delete();
  }

  Future<void> toggleUserStatus(String uid, bool currentStatus) async {
    await _db.collection('users').doc(uid).update({
      'isActive': !currentStatus,
    });
  }

  Future<void> toggleSelection({
    required UserModel user,
    required JobCardModel card,
    required bool isSelected,
  }) async {
    final safeCardId = normalizeDocId(card.jobCardNumber);
    final selectionDocId = '${user.uid}_$safeCardId';
    final selectionRef = _db.collection('selections').doc(selectionDocId);
    final userRef = _db.collection('users').doc(user.uid);

    final batch = _db.batch();

    if (isSelected) {
      batch.set(selectionRef, {
        'uid': user.uid,
        'userId': user.userId,
        'jobCardNumber': card.jobCardNumber,
        'name': card.name,
        'selectedAt': FieldValue.serverTimestamp(),
      });
      batch.update(userRef, {'selectedCount': FieldValue.increment(1)});
    } else {
      batch.delete(selectionRef);
      batch.update(userRef, {'selectedCount': FieldValue.increment(-1)});
    }

    await batch.commit();
  }
}
