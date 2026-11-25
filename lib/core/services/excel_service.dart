import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/selection_model.dart';

class ExcelService {
  Future<List>> pickAndParseMasterExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return [];
    }

    final bytes = result.files.first.bytes ??
        await File(result.files.first.path!).readAsBytes();
    final excel = Excel.decodeBytes(bytes);

    final Map<String, String> uniqueRecords = {};

    for (var table in excel.tables.keys) {
      final sheet = excel.tables[table];
      if (sheet == null) continue;

      for (int rowIndex = 0; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.rows[rowIndex];
        if (row.length < 2) continue;

        final rawCard = row[0]?.value?.toString().trim() ?? '';
        final rawName = row[1]?.value?.toString().trim() ?? '';

        if (rawCard.isEmpty || rawName.isEmpty) continue;

        if (rowIndex == 0 &&
            (rawCard.toLowerCase().contains('job') ||
                rawCard.toLowerCase().contains('sl'))) {
          continue;
        }

        if (!uniqueRecords.containsKey(rawCard)) {
          uniqueRecords[rawCard] = rawName;
        }
      }
      break;
    }

    return uniqueRecords.entries
        .map((e) => {'jobCardNumber': e.key, 'name': e.value})
        .toList();
  }

  Future<File> generateSelectedExcel({
    required String userId,
    required List<SelectionModel> selections,
  }) async {
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Selected_Job_Cards'];
    excel.delete('Sheet1');

    CellStyle headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1B5E20'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
    );

    final headers = ['SL', 'Job Card Number', 'Name'];
    for (int i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    for (int i = 0; i < selections.length; i++) {
      final item = selections[i];
      final rowIdx = i + 1;

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx))
          .value = IntCellValue(i + 1);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx))
          .value = TextCellValue(item.jobCardNumber);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIdx))
          .value = TextCellValue(item.name);
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final cleanUserId = userId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
    final fileName = '${cleanUserId}_Selected_JobCards_$dateStr.xlsx';

    Directory? directory;
    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        directory = await getApplicationDocumentsDirectory();
      }
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    final filePath = '${directory.path}/$fileName';
    final fileBytes = excel.save();

    if (fileBytes == null) {
      throw Exception('Excel ফাইল তৈরি করতে সমস্যা হয়েছে।');
    }

    final file = File(filePath);
    await file.writeAsBytes(fileBytes, flush: true);
    return file;
  }
}
