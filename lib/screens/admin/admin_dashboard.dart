import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service.dart';
import '../auth/login_screen.dart';
import 'excel_upload_screen.dart';
import 'user_management.dart';
import 'job_card_manage.dart';

class AdminDashboard extends StatelessWidget {
  final UserModel adminUser;
  const AdminDashboard({super.key, required this.adminUser});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await AuthService().logout();
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'স্বাগতম, ${adminUser.userName}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: db.collection('job_cards').snapshots(),
                    builder: (context, snap) {
                      final count = snap.hasData ? snap.data!.docs.length : 0;
                      return _StatCard(
                        title: 'Total Job Cards',
                        value: '$count',
                        icon: Icons.credit_card,
                        color: Colors.blue.shade700,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: db.collection('users').where('role', isEqualTo: 'user').snapshots(),
                    builder: (context, snap) {
                      final count = snap.hasData ? snap.data!.docs.length : 0;
                      return _StatCard(
                        title: 'Total Users',
                        value: '$count',
                        icon: Icons.people,
                        color: Colors.orange.shade800,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: db.collection('selections').snapshots(),
              builder: (context, snap) {
                final count = snap.hasData ? snap.data!.docs.length : 0;
                return _StatCard(
                  title: 'Total Selections (All Users)',
                  value: '$count',
                  icon: Icons.check_circle,
                  color: Colors.green.shade700,
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Admin Controls',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _MenuTile(
              title: 'Upload Master Excel (.xlsx)',
              subtitle: 'Column A (Job Card) & Column B (Name) আপলোড করুন',
              icon: Icons.upload_file,
              color: Colors.teal,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExcelUploadScreen()),
              ),
            ),
            _MenuTile(
              title: 'User Management',
              subtitle: 'নতুন User তৈরি, Active/Deactive এবং Selection সংখ্যা দেখুন',
              icon: Icons.manage_accounts,
              color: Colors.indigo,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserManagementScreen()),
              ),
            ),
            _MenuTile(
              title: 'Job Card Management',
              subtitle: 'একক Job Card যোগ, পরিবর্তন বা ডিলিট করুন',
              icon: Icons.edit_document,
              color: Colors.deepPurple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JobCardManageScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
