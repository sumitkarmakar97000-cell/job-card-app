import 'package:flutter/material.dart';
import '../../core/services/excel_service.dart';
import '../../core/services/firestore_service.dart';

class ExcelUploadScreen extends StatefulWidget {
  const ExcelUploadScreen({super.key});

  @override
  State<ExcelUploadScreen> createState() => _ExcelUploadScreenState();
}

class _ExcelUploadScreenState extends State<ExcelUploadScreen> {
  final ExcelService _excelService = ExcelService();
  final FirestoreService _firestoreService = FirestoreService();

  List> _parsedData = [];
  bool _isUploading = false;
  double _progress = 0.0;
  String _statusMessage = '';

  Future<void> _pickFile() async {
    setState(() {
      _statusMessage = 'Excel ফাইল পড়া হচ্ছে...';
      _parsedData = [];
    });

    try {
      final data = await _excelService.pickAndParseMasterExcel();
      setState(() {
        _parsedData = data;
        _statusMessage = data.isEmpty
            ? 'কোনো বৈধ ডাটা পাওয়া যায়নি। Column A-তে Job Card এবং Column B-তে Name রাখুন।'
            : 'মোট ${data.length} টি ইউনিক রেকর্ড পাওয়া গেছে। আপলোড করতে নিচের বাটনে ক্লিক করুন।';
      });
    } catch (e) {
      setState(() => _statusMessage = 'Error: $e');
    }
  }

  Future<void> _uploadToDatabase() async {
    if (_parsedData.isEmpty) return;

    setState(() {
      _isUploading = true;
      _progress = 0.0;
    });

    try {
      final result = await _firestoreService.uploadMasterJobCards(
        _parsedData,
        (prog) => setState(() => _progress = prog),
      );

      setState(() {
        _isUploading = false;
        _parsedData = [];
        _statusMessage =
            'সফলভাবে আপলোড হয়েছে!\nনতুন যোগ হয়েছে: ${result['added']} টি\nডুপ্লিকেট বাদ দেওয়া হয়েছে: ${result['duplicates']} টি';
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _statusMessage = 'আপলোড ব্যর্থ হয়েছে: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Excel Upload'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Excel ফাইল ফরম্যাট নির্দেশিকা:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text('• ফাইলটি অবশ্যই .xlsx ফরম্যাটে হতে হবে।'),
                  Text('• Column A: Job Card Number'),
                  Text('• Column B: Name (বাংলা বা ইংরেজি)'),
                  Text('• পুরনো ডাটা মুছবে না এবং Duplicate Entry অটোমেটিক বাদ যাবে।'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.folder_open),
              label: const Text('SELECT EXCEL FILE (.xlsx)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.teal.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: _isUploading ? null : _pickFile,
            ),
            const SizedBox(height: 16),
            if (_statusMessage.isNotEmpty)
              Card(
                color: Colors.amber.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_statusMessage, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            if (_isUploading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _progress, minHeight: 10),
              const SizedBox(height: 8),
              Text('${(_progress * 100).toStringAsFixed(0)}% সম্পন্ন হয়েছে...', textAlign: TextAlign.center),
            ],
            if (_parsedData.isNotEmpty && !_isUploading) ...[
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: _parsedData.length > 50 ? 50 : _parsedData.length,
                  itemBuilder: (context, index) {
                    final item = _parsedData[index];
                    return ListTile(
                      dense: true,
                      leading: Text('${index + 1}'),
                      title: Text(item['jobCardNumber']!),
                      subtitle: Text(item['name']!),
                    );
                  },
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.cloud_upload),
                label: Text('UPLOAD ${_parsedData.length} RECORDS TO DATABASE'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
                onPressed: _uploadToDatabase,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
