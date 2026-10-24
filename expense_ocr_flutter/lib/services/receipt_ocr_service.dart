import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ReceiptOcrService {
  ReceiptOcrService._();

  static final TextRecognizer _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  static Future<String> recognizeText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);

    final recognizedText = await _recognizer.processImage(inputImage);

    return recognizedText.text.trim();
  }

  static Future<void> dispose() async {
    await _recognizer.close();
  }
}
