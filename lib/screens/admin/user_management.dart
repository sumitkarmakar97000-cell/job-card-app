import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  void _showCreateUserDialog() {
    final userIdCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool isCreating = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('নতুন User তৈরি করুন'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: userIdCtrl,
                decoration: const InputDecoration(labelText: 'User ID (যেমন: USER01)'),
              ),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'User Name (বাংলা বা ইংরেজি)'),
              ),
              TextField(
                controller: passCtrl,
                decoration: const InputDecoration(labelText: 'Password (কমপক্ষে ৬ অক্ষর)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isCreating ? null : () => Navigator.pop(ctx),
              child: const Text('বাতিল'),
            ),
            ElevatedButton(
              onPressed: isCreating
                  ? null
                  : () async {
                      if (userIdCtrl.text.isEmpty || nameCtrl.text.isEmpty || passCtrl.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('সঠিক তথ্য দিন (পাসওয়ার্ড কমপক্ষে ৬ অক্ষর হতে হবে)')),
                        );
                        return;
                      }
                      setDialogState(() => isCreating = true);
                      try {
                        await _authService.createUserByAdmin(
                          userId: userIdCtrl.text,
                          userName: nameCtrl.text,
                          password: passCtrl.text,
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('নতুন User সফলভাবে তৈরি হয়েছে!')),
                        );
                      } catch (e) {
                        setDialogState(() => isCreating = false);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
              child: isCreating
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('তৈরি করুন'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateUserDialog,
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('New User'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'user')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final users = snapshot.data!.docs
              .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();

          if (users.isEmpty) {
            return const Center(child: Text('এখনো কোনো User তৈরি করা হয়নি।'));
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80, top: 8, left: 12, right: 12),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: user.isActive ? Colors.green.shade100 : Colors.red.shade100,
                    child: Icon(
                      user.isActive ? Icons.check_circle : Icons.block,
                      color: user.isActive ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text('${user.userName} (${user.userId})',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Selected Job Cards: ${user.selectedCount} টি'),
                  trailing: Switch(
                    value: user.isActive,
                    activeThumbColor: Colors.green,
                    onChanged: (_) => _firestoreService.toggleUserStatus(user.uid, user.isActive),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
