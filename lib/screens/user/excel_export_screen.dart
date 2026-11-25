import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/models/selection_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/excel_service.dart';

class ExcelExportScreen extends StatefulWidget {
  final UserModel currentUser;
  final List<SelectionModel> selectedList;

  const ExcelExportScreen({
    super.key,
    required this.currentUser,
    required this.selectedList,
  });

  @override
  State<ExcelExportScreen> createState() => _ExcelExportScreenState();
}

class _ExcelExportScreenState extends State<ExcelExportScreen> {
  final ExcelService _excelService = ExcelService();
  bool _isGenerating = false;
  File? _generatedFile;

  Future<void> _exportNow() async {
    setState(() => _isGenerating = true);
    try {
      final file = await _excelService.generateSelectedExcel(
        userId: widget.currentUser.userId,
        selections: widget.selectedList,
      );
      setState(() {
        _generatedFile = file;
        _isGenerating = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Excel ফাইল সেভ হয়েছে:\n${file.path}'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      setState(() => _isGenerating = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Selected Excel Export'),
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Total Selected Records: ${widget.selectedList.length}',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                    ),
                    const SizedBox(height: 6),
                    Text('User: ${widget.currentUser.userName} (${widget.currentUser.userId})'),
                    const Text('Format: SL | Job Card Number | Name (.xlsx)'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Selected Data Preview:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                child: ListView.separated(
                  itemCount: widget.selectedList.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = widget.selectedList[index];
                    return ListTile(
                      dense: true,
                      leading: Text('${index + 1}'),
                      title: Text(item.jobCardNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(item.name),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_generatedFile != null) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('OPEN EXCEL'),
                      onPressed: () => OpenFilex.open(_generatedFile!.path),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.share),
                      label: const Text('SHARE'),
                      onPressed: () => Share.shareXFiles([XFile(_generatedFile!.path)]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.file_download),
                label: _isGenerating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('GENERATE & DOWNLOAD .XLSX', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isGenerating ? null : _exportNow,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
