// 🔥 Importaciones necesarias
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

// 🔥 Main App
void main() {
  runApp(const OCRApp());
}

class OCRApp extends StatelessWidget {
  const OCRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: OCRHomePage(),
    );
  }
}

class OCRHomePage extends StatefulWidget {
  const OCRHomePage({super.key});

  @override
  State<OCRHomePage> createState() => _OCRHomePageState();
}

class _OCRHomePageState extends State<OCRHomePage> {
  File? selectedImage;
  List<List<String>> structuredTable = [];
  List<Map<String, dynamic>> debugWords = []; // 🔥 Datos de depuración para la imagen


  Future<void> _pickAndRecognizeText() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
        structuredTable = [];
        debugWords = []; // Limpiar depuración visual
      });

      final inputImage = InputImage.fromFile(selectedImage!);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      List<Map<String, dynamic>> wordData = [];
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          for (TextElement element in line.elements) {
            final boundingBox = element.boundingBox;

              final centerX = (boundingBox.left + boundingBox.right) / 2;
              final centerY = (boundingBox.top + boundingBox.bottom) / 2;
              wordData.add({
                "text": element.text,
                "centerX": centerX,
                "centerY": centerY,
              });

              debugWords.add({
                "text": element.text,
                "boundingBox": boundingBox,
              });

              // 🔥 Debug log en consola
              print("Detectado: '${element.text}' en (${centerX.toStringAsFixed(2)}, ${centerY.toStringAsFixed(2)})");
            }
          
        }
      }

      structuredTable = _groupWordsIntoTable(wordData);
      setState(() {});
    }
  }



  Future<double> estimateSkewAngle(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes)!;

    final width = image.width;
    final height = image.height;

    List<double> angles = [];

    for (int y = 0; y < height - 1; y += 10) {
      for (int x = 0; x < width - 10; x++) {
        int p1 = img.getLuminance(image.getPixel(x, y)).toInt();
        int p2 = img.getLuminance(image.getPixel(x + 10, y + 1)).toInt();

        if ((p1 - p2).abs() > 30) {
          double dx = 10;
          double dy = 1;
          double angle = atan2(dy, dx) * 180 / pi;
          angles.add(angle);
        }
      }
    }

    if (angles.isEmpty) return 0.0;

    angles.sort();
    double median = angles[angles.length ~/ 2];
    print("📐 Ángulo estimado: $median°");
    return median;
  }


  Future<File> rotateImage(File originalImage, double angleDegrees) async {
    final bytes = await originalImage.readAsBytes();
    final original = img.decodeImage(bytes)!;

    final rotated = img.copyRotate(original, angle: -angleDegrees); // negativo para corregir

    final tempDir = await getTemporaryDirectory();
    final rotatedPath = '${tempDir.path}/rotated_image.jpg';

    final rotatedFile = File(rotatedPath);
    await rotatedFile.writeAsBytes(img.encodeJpg(rotated));
    return rotatedFile;
  }

  List<List<String>> _groupWordsIntoTable(List<Map<String, dynamic>> words) {
    if (words.isEmpty) return [];

    words.sort((a, b) => a["centerY"].compareTo(b["centerY"]));

    double averageAngle = _calculateAverageAngle(words);

    words = words.map((word) {
      word["centerX"] = _rotatePoint(word["centerX"], word["centerY"], averageAngle)["x"];
      return word;
    }).toList();

    List<List<String>> rows = _clusterColumns(words);

    return rows;
  }

  double _calculateAverageAngle(List<Map<String, dynamic>> words) {
    List<double> angles = [];
    for (int i = 0; i < words.length - 1; i++) {
      double dx = words[i + 1]["centerX"] - words[i]["centerX"];
      double dy = words[i + 1]["centerY"] - words[i]["centerY"];
      if (dx != 0) angles.add(atan2(dy, dx) * (180 / pi));
    }
    return angles.isNotEmpty ? angles.average : 0.0;
  }

  Map<String, double> _rotatePoint(double x, double y, double angle) {
    double radians = angle * (pi / 180);
    double rotatedX = x * cos(radians) - y * sin(radians);
    return {"x": rotatedX, "y": y};
  }

  List<List<String>> _clusterColumns(List<Map<String, dynamic>> words) {
    words.sort((a, b) => a["centerX"].compareTo(b["centerX"]));

    double columnThreshold = 50.0;
    List<List<Map<String, dynamic>>> clusters = [];
    List<Map<String, dynamic>> currentCluster = [];

    for (var word in words) {
      if (currentCluster.isEmpty || (word["centerX"] - currentCluster.last["centerX"]).abs() < columnThreshold) {
        currentCluster.add(word);
      } else {
        clusters.add(currentCluster);
        currentCluster = [word];
      }
    }
    if (currentCluster.isNotEmpty) clusters.add(currentCluster);

    List<List<String>> structuredTable = [];
    for (var cluster in clusters) {
      structuredTable.add(cluster.map<String>((word) => word["text"].toString()).toList());
    }

    return structuredTable;
  }

  // 🔥 Debug visual sobre la imagen
  Widget _buildDebugOverlay() {
    if (debugWords.isEmpty) return Container();

    return Stack(
      children: debugWords.map<Widget>((word) {
        final box = word["boundingBox"];
        return Positioned(
          left: box.left,
          top: box.top,
          child: Container(
            padding: const EdgeInsets.all(2.0),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              word["text"],
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget buildTable() {
    if (structuredTable.isEmpty) {
      return const Center(child: Text("No hay datos tabulares para mostrar."));
    }

    int maxColumns = structuredTable.map((row) => row.length).reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: List.generate(
          maxColumns,
          (index) => DataColumn(label: Text("Columna ${index + 1}")),
        ),
        rows: structuredTable.map<DataRow>((row) {
          return DataRow(
            cells: List.generate(
              maxColumns,
              (index) => DataCell(Text(index < row.length ? row[index] : "")),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OCR Tabular con ML Kit')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (selectedImage != null)
              Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Image.file(selectedImage!, height: 200, fit: BoxFit.contain),
                  ),
                  _buildDebugOverlay(), // 🔥 Overlay de debug
                ],
              ),
            Expanded(child: buildTable()),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickAndRecognizeText,
              child: const Text('Seleccionar Imagen y Procesar OCR'),
            ),
          ],
        ),
      ),
    );
  }
}
