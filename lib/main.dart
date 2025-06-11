// 🔥 Importaciones necesarias
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:io';
import 'dart:convert'; // Para convertir a JSON
import 'package:http/http.dart' as http; // Para hacer peticiones HTTP
import 'dart:async'; // Para TimeoutException
import 'package:flutter/foundation.dart';

// 🔥 Main App
void main() {
  runApp(const OCRApp());
}

// Tu función que se usará en compute (muy simple en este caso)
List<List<String>> parseTable(List<List<String>> data) {
  return data;
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
  @override
  State<OCRHomePage> createState() => _OCRHomePageState();
}

class _OCRHomePageState extends State<OCRHomePage> {
  File? selectedImage;
  List<List<String>> structuredTable = [];
  List<Map<String, dynamic>> debugWords = []; // 🔥 Datos de depuración visual

  // URL de tu API (ajusta según convenga)
  final String apiUrl = "https://ocrticketing-production.up.railway.app/ocr-json";

bool _isProcessing = false;
Future<void> _pickAndRecognizeText() async {
  if (_isProcessing) return;  // evita reentradas
  _isProcessing = true;


  try {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,    // limitar ancho
      maxHeight: 800,   // limitar alto
      imageQuality: 80,  // calidad (0-100)
    );
    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
        structuredTable = [];
        debugWords = [];
      });

      final inputImage = InputImage.fromFile(selectedImage!);
      final textDetector = GoogleMlKit.vision.textRecognizer();

      try {
        final RecognizedText recognizedText = await textDetector.processImage(inputImage);

        List<Map<String, dynamic>> wordData = [];
        List<Map<String, dynamic>> tempDebugWords = [];

        for (TextBlock block in recognizedText.blocks) {
          for (TextLine line in block.lines) {
            for (TextElement element in line.elements) {
              final boundingBox = element.boundingBox;

                final centerX = (boundingBox.left + boundingBox.right) / 2;
                final centerY = (boundingBox.top + boundingBox.bottom) / 2;

                wordData.add({
                  "text": element.text,
                  "boundingBox": {
                    "left": boundingBox.left,
                    "top": boundingBox.top,
                    "right": boundingBox.right,
                    "bottom": boundingBox.bottom,
                  },
                  "centerX": centerX,
                  "centerY": centerY,
                });

                tempDebugWords.add({
                  "text": element.text,
                  "boundingBox": boundingBox,
                });

                //print("Detectado: '${element.text}' en (${centerX.toStringAsFixed(2)}, ${centerY.toStringAsFixed(2)})");
              }
            
          }
        }

        setState(() {
          debugWords = tempDebugWords;
        });

        // Enviar datos JSON al backend y mostrar respuesta
        await _sendOcrJson(wordData);

        // Agrupar en tabla usando los datos recibidos localmente

      } catch (e) {
        print("Error al procesar imagen: $e");
      } finally {
        await textDetector.close();
        _isProcessing = false; // Permite nuevas selecciones
         ///setState(() {}); // Actualiza UI para reflejar el estado
      }
    } else {
      print("No se seleccionó ninguna imagen.");
    }
  } catch (e) {
    print("Error al seleccionar imagen: $e");
  }
}

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("OK"))
        ],
      ),
    );
  }

void _showSnackBar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}






  Future<void> _sendOcrJson(List<Map<String, dynamic>> data) async {
    final Map<String, dynamic> payload = {"elements": data};
    final headers = {"Content-Type": "application/json"};
    final body = json.encode(payload);

    try {
      final response = await http
          .post(Uri.parse(apiUrl), headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData.containsKey("rows") && responseData["rows"] is List) {
          final rawRows = responseData["rows"] as List;

          final tableData = rawRows.map<List<String>>((row) {
            if (row is Map<String, dynamic>) {
              return row.values.map((v) => v.toString()).toList();
            } else {
              return [];
            }
          }).toList();

          // Debug para ver la data antes de compute
          print("DEBUG antes de compute: $tableData");

          // Ejecutar procesamiento en isolate
          final parsedTable = await compute(parseTable, tableData);

          setState(() {
            structuredTable = parsedTable;
          });

          _showSnackBar("✅ Datos tabulares recibidos correctamente.");
        } else {
          _showErrorDialog("⚠️ El formato de respuesta no es válido.");
        }
      } else if (response.statusCode == 400) {
        _showErrorDialog("❌ Error de solicitud: ${response.body}");
      } else {
        _showErrorDialog("❌ Error del servidor: ${response.statusCode}");
      }
    } on TimeoutException {
      _showErrorDialog("⏱️ La solicitud tardó demasiado y fue cancelada.");
    } on SocketException {
      _showErrorDialog("📡 No se pudo conectar con el servidor.");
    } on FormatException catch (e) {
      _showErrorDialog("🧨 Error al interpretar la respuesta: $e");
    } catch (e) {
      _showErrorDialog("🚨 Error inesperado: $e");
    }
  }


/// Construye la tabla con los datos tabulados.
  Widget buildTable() {
    if (structuredTable.isEmpty) {
      return const Center(child: Text("No hay datos tabulares para mostrar."));
    }

    int maxColumns = structuredTable
        .map((row) => row.length)
        .fold(0, (prev, curr) => curr > prev ? curr : prev);

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
