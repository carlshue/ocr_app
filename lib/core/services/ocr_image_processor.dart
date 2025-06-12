import 'dart:io';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/ocr_word.dart';

/// Procesador de imagen para OCR que incluye preprocesamiento como corrección de inclinación.
class OcrImageProcessor {
  /// 🔍 Corrige la inclinación y luego extrae palabras con ML Kit OCR.
  static Future<List<OcrWord>> extractWords(File image) async {
    final correctedImage = await deskewImage(image);
    final inputImage = InputImage.fromFile(correctedImage);

    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();

    final words = <OcrWord>[];

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          words.add(OcrWord(
            text: element.text,
            boundingBox: element.boundingBox,
          ));
        }
      }
    }

    return words;
  }

  /// 🌀 Corrige la inclinación de la imagen usando un método nativo.
  static Future<File> deskewImage(File imageFile) async {
    const platform = MethodChannel('ocr_image_processor');

    try {
      final result = await platform.invokeMethod<String>(
        'deskewImage',
        {'path': imageFile.path},
      );

      if (result == null) throw Exception("deskewImage retornó null");

      return File(result);
    } catch (e) {
      final isSkewTooLarge = e.toString().contains('Angle too large');

      if (isSkewTooLarge) {
        throw Exception('La imagen está muy inclinada. Por favor, endereza la imagen y vuelve a intentarlo.');
      }

      print("Error en deskewImage: $e");
      return imageFile; // Fallback sin corrección
    }
  }
}
