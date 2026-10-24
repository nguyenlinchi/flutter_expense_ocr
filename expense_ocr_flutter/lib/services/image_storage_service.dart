import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageStorageService {
  ImageStorageService._();

  static Future<String> saveReceiptImage(
    String sourcePath,
  ) async {
    final sourceFile = File(sourcePath);

    if (!await sourceFile.exists()) {
      throw Exception('Không tìm thấy ảnh hóa đơn.');
    }

    final appDirectory = await getApplicationDocumentsDirectory();

    final receiptDirectory = Directory(
      p.join(appDirectory.path, 'receipts'),
    );

    if (!await receiptDirectory.exists()) {
      await receiptDirectory.create(recursive: true);
    }

    final extension =
        p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);

    final fileName =
        'receipt_${DateTime.now().microsecondsSinceEpoch}$extension';

    final destinationPath = p.join(receiptDirectory.path, fileName);

    final savedFile = await sourceFile.copy(destinationPath);

    return savedFile.path;
  }

  static Future<void> deleteReceiptImage(
    String? imagePath,
  ) async {
    if (imagePath == null || imagePath.isEmpty) {
      return;
    }

    final file = File(imagePath);

    if (await file.exists()) {
      await file.delete();
    }
  }
}
