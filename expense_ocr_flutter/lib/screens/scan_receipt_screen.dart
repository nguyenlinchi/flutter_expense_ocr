
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/receipt_data.dart';
import '../services/image_storage_service.dart';
import '../services/receipt_ocr_service.dart';
import '../services/receipt_parser.dart';
import 'review_expense_screen.dart';

class ScanReceiptScreen extends StatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  final ImagePicker _picker = ImagePicker();

  String? _imagePath;
  String _recognizedText = '';
  ReceiptData? _parsedData;

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _pickImage(ImageSource source) async {
    if (_isLoading) return;

    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2000,
      );

      // Người dùng đóng camera hoặc hủy chọn ảnh.
      if (pickedFile == null || !mounted) return;

      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _recognizedText = '';
        _parsedData = null;
        _imagePath = null;
      });

      // Sao chép ảnh vào thư mục riêng của ứng dụng.
      final savedPath =
          await ImageStorageService.saveReceiptImage(pickedFile.path);

      if (!mounted) return;

      setState(() {
        _imagePath = savedPath;
      });

      // OCR chạy trên thiết bị bằng Google ML Kit.
      final text = await ReceiptOcrService.recognizeText(savedPath);

      if (!mounted) return;

      if (text.trim().isEmpty) {
        setState(() {
          _recognizedText = '';
          _parsedData = null;
          _errorMessage =
              'Không nhận diện được chữ. Hãy thử ảnh rõ nét hơn, đủ sáng và chụp thẳng hóa đơn.';
        });
        return;
      }

      final parsed = ReceiptParser.parse(text);

      setState(() {
        _recognizedText = text;
        _parsedData = parsed;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Không thể xử lý ảnh hóa đơn: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearImage() {
    if (_isLoading) return;

    setState(() {
      _imagePath = null;
      _recognizedText = '';
      _parsedData = null;
      _errorMessage = null;
    });
  }

  Future<void> _openReview() async {
    final data = _parsedData;
    final path = _imagePath;

    if (data == null || path == null || _isLoading) return;

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ReviewExpenseScreen(
          receiptData: data,
          imagePath: path,
        ),
      ),
    );

    if (!mounted) return;

    if (saved == true) {
      // Báo cho màn hình trước biết giao dịch đã được lưu.
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _parsedData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét hóa đơn'),
        actions: [
          if (_imagePath != null)
            IconButton(
              tooltip: 'Xóa ảnh hiện tại',
              onPressed: _isLoading ? null : _clearImage,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Nhận diện hóa đơn bằng AI',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chụp hóa đơn hoặc chọn ảnh có sẵn. '
              'Kiểm tra thông tin nhận diện trước khi lưu giao dịch.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),

            // Khu vực xem trước ảnh.
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 210),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _imagePath == null
                  ? const SizedBox(
                      height: 210,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 58,
                          ),
                          SizedBox(height: 12),
                          Text('Ảnh hóa đơn sẽ hiển thị tại đây'),
                        ],
                      ),
                    )
                  : Image.file(
                      File(_imagePath!),
                      height: 300,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return const SizedBox(
                          height: 210,
                          child: Center(
                            child: Text('Không thể hiển thị ảnh.'),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Chụp ảnh'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Thư viện'),
                  ),
                ),
              ],
            ),

            if (_isLoading) ...[
              const SizedBox(height: 24),
              const Center(
                child: CircularProgressIndicator(),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text('Đang nhận diện chữ trên hóa đơn...'),
              ),
            ],

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context)
                          .colorScheme
                          .onErrorContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (data != null) ...[
              const SizedBox(height: 24),
              Text(
                'Thông tin nhận diện',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _RecognizedInfoRow(
                label: 'Cửa hàng',
                value: data.merchant ?? 'Chưa nhận diện',
              ),
              _RecognizedInfoRow(
                label: 'Số tiền',
                value: data.amount == null
                    ? 'Chưa nhận diện'
                    : NumberFormat.currency(
                        locale: 'vi_VN',
                        symbol: '₫',
                        decimalDigits: 0,
                      ).format(data.amount),
              ),
              _RecognizedInfoRow(
                label: 'Ngày',
                value: data.date == null
                    ? 'Chưa nhận diện'
                    : DateFormat('dd/MM/yyyy').format(data.date!),
              ),
              _RecognizedInfoRow(
                label: 'Danh mục gợi ý',
                value: data.category,
              ),
            ],

            if (_recognizedText.isNotEmpty) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Xem toàn bộ văn bản OCR'),
                subtitle: const Text(
                  'Dùng để kiểm tra lỗi nhận diện',
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(_recognizedText),
                  ),
                ],
              ),
            ],

            if (data != null && _imagePath != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _openReview,
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Kiểm tra và lưu giao dịch'),
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _RecognizedInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _RecognizedInfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
