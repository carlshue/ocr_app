// 🔥 BLOQUE 1: Importaciones
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:io';
import 'dart:math';

// 🔥 BLOQUE 2: Main App
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

// 🔥 BLOQUE 3: Estado y Variables Principales
class OCRHomePage extends StatefulWidget {
  @override
  State<OCRHomePage> createState() => _OCRHomePageState();
}

class _OCRHomePageState extends State<OCRHomePage> {
  File? selectedImage;
  List<List<String>> structuredTable = [];

  // 🔥 Función para detectar texto y agrupar por filas y columnas
  Future<void> _pickAndRecognizeText() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
        structuredTable = [];
      });

      final inputImage = InputImage.fromFile(selectedImage!);
      final textDetector = GoogleMlKit.vision.textRecognizer();
      final RecognizedText recognizedText = await textDetector.processImage(inputImage);
      await textDetector.close();

      // 🔥 Extraer coordenadas y texto de cada palabra
      List<Map<String, dynamic>> wordData = [];
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          for (TextElement element in line.elements) {
            final boundingBox = element.boundingBox;
            if (boundingBox != null) {
              final centerX = (boundingBox.left + boundingBox.right) / 2;
              final centerY = (boundingBox.top + boundingBox.bottom) / 2;
              wordData.add({
                "text": element.text,
                "centerX": centerX,
                "centerY": centerY,
              });
            }
          }
        }
      }

      // 🔥 Aplicar heurística para detectar filas y columnas
      structuredTable = _groupWordsIntoTable(wordData);

      setState(() {}); // Refrescar UI
    }
  }

  // 🔥 Agrupar palabras en filas basadas en coordenadas verticales
  List<List<String>> _groupWordsIntoTable(List<Map<String, dynamic>> words) {
    if (words.isEmpty) return [];

    words.sort((a, b) => a["centerY"].compareTo(b["centerY"])); // Ordenar por altura

    List<List<String>> rows = [];
    List<String> currentRow = [];
    double prevY = words.first["centerY"];
    double threshold = 30.0; // Tolerancia de distancia vertical

    for (var word in words) {
      if ((word["centerY"] - prevY).abs() > threshold) {
        rows.add(currentRow);
        currentRow = [];
      }
      currentRow.add(word["text"]);
      prevY = word["centerY"];
    }

    if (currentRow.isNotEmpty) rows.add(currentRow); // Última fila
    return rows;
  }

  // 🔥 Construcción de la tabla en Flutter
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
              (index) => DataCell(Text(index < row.length ? row[index] : "")), // Rellenar con vacío
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
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Image.file(selectedImage!, height: 200, fit: BoxFit.contain),
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