import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/job_card_model.dart';
import '../../core/services/firestore_service.dart';

class JobCardManageScreen extends StatefulWidget {
  const JobCardManageScreen({super.key});

  @override
  State<JobCardManageScreen> createState() => _JobCardManageScreenState();
}

class _JobCardManageScreenState extends State<JobCardManageScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _searchQuery = '';

  void _showAddOrEditDialog({JobCardModel? existingCard}) {
    final isEdit = existingCard != null;
    final cardCtrl = TextEditingController(text: existingCard?.jobCardNumber ?? '');
    final nameCtrl = TextEditingController(text: existingCard?.name ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Job Card আপডেট করুন' : 'নতুন Job Card যোগ করুন'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cardCtrl,
              enabled: !isEdit,
              decoration: const InputDecoration(labelText: 'Job Card Number'),
            ),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name (বাংলা বা ইংরেজি)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          ElevatedButton(
            onPressed: () async {
              if (cardCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) return;
              try {
                await _firestoreService.saveSingleJobCard(
                  cardCtrl.text,
                  nameCtrl.text,
                  isEdit: isEdit,
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                );
              }
            },
            child: const Text('সেভ করুন'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Job Cards'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOrEditDialog(),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Job Card Number অথবা Name দিয়ে খুঁজুন...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('job_cards').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final cards = snapshot.data!.docs
                    .map((doc) => JobCardModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                    .where((c) =>
                        c.jobCardNumber.toLowerCase().contains(_searchQuery) ||
                        c.name.toLowerCase().contains(_searchQuery))
                    .toList();

                return ListView.builder(
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    return ListTile(
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text(card.jobCardNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(card.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showAddOrEditDialog(existingCard: card),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _firestoreService.deleteJobCard(card.id),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
