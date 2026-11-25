import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/job_card_model.dart';
import '../../core/models/selection_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../auth/login_screen.dart';
import 'excel_export_screen.dart';

enum FilterMode { all, selected, pending }

class UserDashboard extends StatefulWidget {
  final UserModel currentUser;
  const UserDashboard({super.key, required this.currentUser});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  FilterMode _filterMode = FilterMode.all;

  void _showChangePasswordDialog() {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    bool isUpdating = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Password পরিবর্তন করুন'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'বর্তমান Password'),
              ),
              TextField(
                controller: newPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'নতুন Password (কমপক্ষে ৬ অক্ষর)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
            ElevatedButton(
              onPressed: isUpdating
                  ? null
                  : () async {
                      if (newPassCtrl.text.trim().length < 6) return;
                      setDialogState(() => isUpdating = true);
                      try {
                        await _authService.changePassword(oldPassCtrl.text, newPassCtrl.text);
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password সফলভাবে পরিবর্তন হয়েছে!')),
                        );
                      } catch (e) {
                        setDialogState(() => isUpdating = false);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
              child: const Text('আপডেট'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return StreamBuilder<DocumentSnapshot>(
      stream: db.collection('users').doc(widget.currentUser.uid).snapshots(),
      builder: (context, userSnap) {
        if (userSnap.hasData && userSnap.data!.exists) {
          final liveUser = UserModel.fromMap(
            userSnap.data!.data() as Map<String, dynamic>,
            userSnap.data!.id,
          );
          if (!liveUser.isActive) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await _authService.logout();
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            });
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.currentUser.userName, style: const TextStyle(fontSize: 16)),
                Text('ID: ${widget.currentUser.userId}', style: const TextStyle(fontSize: 12)),
              ],
            ),
            backgroundColor: Colors.teal.shade800,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.key),
                tooltip: 'Change Password',
                onPressed: _showChangePasswordDialog,
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
                onPressed: () async {
                  await _authService.logout();
                  if (!context.mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
            ],
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: db.collection('job_cards').snapshots(),
            builder: (context, cardSnap) {
              if (!cardSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final allCards = cardSnap.data!.docs
                  .map((d) => JobCardModel.fromMap(d.data() as Map<String, dynamic>, d.id))
                  .toList();

              return StreamBuilder<QuerySnapshot>(
                stream: db
                    .collection('selections')
                    .where('uid', isEqualTo: widget.currentUser.uid)
                    .snapshots(),
                builder: (context, selSnap) {
                  final Map<String, SelectionModel> mySelectionMap = {};
                  if (selSnap.hasData) {
                    for (var doc in selSnap.data!.docs) {
                      final sel = SelectionModel.fromMap(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      );
                      mySelectionMap[sel.jobCardNumber] = sel;
                    }
                  }

                  final int totalCount = allCards.length;
                  final int selectedCount = mySelectionMap.length;
                  final int pendingCount = totalCount - selectedCount;

                  final filteredCards = allCards.where((card) {
                    final isSelected = mySelectionMap.containsKey(card.jobCardNumber);
                    if (_filterMode == FilterMode.selected && !isSelected) return false;
                    if (_filterMode == FilterMode.pending && isSelected) return false;

                    if (_searchQuery.isNotEmpty) {
                      return card.jobCardNumber.toLowerCase().contains(_searchQuery) ||
                          card.name.toLowerCase().contains(_searchQuery);
                    }
                    return true;
                  }).toList();

                  return Column(
                    children: [
                      Container(
                        color: Colors.teal.shade50,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        child: Row(
                          children: [
                            _MiniStatBox(label: 'Total Cards', count: totalCount, color: Colors.blue.shade800),
                            const SizedBox(width: 8),
                            _MiniStatBox(label: 'My Selected', count: selectedCount, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            _MiniStatBox(label: 'My Pending', count: pendingCount, color: Colors.orange.shade800),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Job Card Number অথবা নাম (বাংলা/English) খুঁজুন...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: Text('সবগুলো ($totalCount)'),
                              selected: _filterMode == FilterMode.all,
                              onSelected: (_) => setState(() => _filterMode = FilterMode.all),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: Text('Selected ($selectedCount)'),
                              selected: _filterMode == FilterMode.selected,
                              selectedColor: Colors.green.shade200,
                              onSelected: (_) => setState(() => _filterMode = FilterMode.selected),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: Text('Pending ($pendingCount)'),
                              selected: _filterMode == FilterMode.pending,
                              selectedColor: Colors.orange.shade200,
                              onSelected: (_) => setState(() => _filterMode = FilterMode.pending),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 8),
                      Container(
                        color: Colors.grey.shade200,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: const Row(
                          children: [
                            SizedBox(width: 45, child: Text('SL', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 4, child: Text('Job Card Number', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 4, child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                            SizedBox(width: 50, child: Text('Select', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                      Expanded(
                        child: filteredCards.isEmpty
                            ? const Center(child: Text('কোনো জব কার্ড পাওয়া যায়নি।'))
                            : ListView.separated(
                                itemCount: filteredCards.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final card = filteredCards[index];
                                  final isChecked = mySelectionMap.containsKey(card.jobCardNumber);

                                  return Container(
                                    color: isChecked ? Colors.green.shade50 : Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 45,
                                          child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.w500)),
                                        ),
                                        Expanded(
                                          flex: 4,
                                          child: Text(
                                            card.jobCardNumber,
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 4,
                                          child: Text(
                                            card.name,
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 50,
                                          child: Checkbox(
                                            value: isChecked,
                                            activeColor: Colors.green.shade700,
                                            onChanged: (bool? newValue) {
                                              if (newValue == null) return;
                                              _firestoreService.toggleSelection(
                                                user: widget.currentUser,
                                                card: card,
                                                isSelected: newValue,
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.download),
                            label: Text(
                              'DOWNLOAD MY SELECTED EXCEL ($selectedCount)',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedCount > 0 ? Colors.green.shade700 : Colors.grey.shade400,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: selectedCount == 0
                                ? () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('ডাউনলোড করার আগে অন্তত ১টি Job Card সিলেক্ট করুন।')),
                                    );
                                  }
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ExcelExportScreen(
                                          currentUser: widget.currentUser,
                                          selectedList: mySelectionMap.values.toList(),
                                        ),
                                      ),
                                    );
                                  },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _MiniStatBox extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _MiniStatBox({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
