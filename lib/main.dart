// 🔥 BLOQUE 1: Importaciones
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  List<dynamic> originalTexts = [];
  List<dynamic> cleanedTexts = [];
  List<dynamic> confidences = [];
  List<dynamic> bboxes = [];
  Map<String, dynamic>? ocrResponse;

  bool showRawJson = false;

  // 🔥 BLOQUE 4: Función para Subir Imagen y Obtener OCR
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://ocrticketing-production.up.railway.app/ocr'), //  http://0.0.0.0:8080 // https://ocrticketing-production.up.railway.app/ocr
      );
      request.files.add(await http.MultipartFile.fromPath('file', pickedFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          originalTexts = data['original_texts'] ?? [];
          cleanedTexts = data['cleaned_texts'] ?? [];
          confidences = data['confidences'] ?? [];
          bboxes = data['bboxes'] ?? [];
          ocrResponse = data;
          showRawJson = false;
        });
      } else {
        setState(() {
          originalTexts = [];
          cleanedTexts = [];
          confidences = [];
          bboxes = [];
          ocrResponse = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.statusCode}')),
        );
      }
    }
  }


  // 🔥 BLOQUE 6: Widget para Mostrar la Tabla OCR
Widget buildOCRTable() {
  if (ocrResponse == null) {
    return const Center(child: Text("No hay datos OCR para mostrar."));
  }

  final List<dynamic> table = ocrResponse?['table'] ?? [];
  final List<dynamic> columns = ocrResponse?['columns'] ?? [];

  if (table.isEmpty || columns.isEmpty) {
    return const Center(child: Text("Tabla vacía."));
  }

  // Construir filas DataRow para DataTable
  final rows = table.map<DataRow>((row) {
    return DataRow(
      cells: List<DataCell>.generate(
        row.length,
        (index) => DataCell(Text(row[index].toString())),
      ),
    );
  }).toList();

  // Construir columnas DataColumn para DataTable
  final dataColumns = columns.map<DataColumn>((colName) {
    return DataColumn(label: Text(colName.toString()));
  }).toList();

  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      columns: dataColumns,
      rows: rows,
      columnSpacing: 20,
      showCheckboxColumn: false,
    ),
  );
}



// Función auxiliar para detectar texto puro (sin números predominantes)
bool _isText(String cell) {
  final trimmed = cell.trim();
  if (trimmed.isEmpty) return false;
  final hasDigits = RegExp(r'\d').hasMatch(trimmed);
  final hasLetters = RegExp(r'[a-zA-Z]').hasMatch(trimmed);
  return hasLetters && (!hasDigits || trimmed.length > 3);
}



  // 🔥 BLOQUE 7: Widget para Mostrar el Debug JSON
  Widget buildDebugJSON() {
    return SingleChildScrollView(
      child: Text(jsonEncode(ocrResponse ?? {})),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OCR App')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Área principal (tabla o JSON), ocupa todo el espacio posible arriba
            Expanded(
              child: showRawJson ? buildDebugJSON() : buildOCRTable(),
            ),
            const SizedBox(height: 16),
            // Botones abajo, con SafeArea y con espacio entre ellos
            SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _pickAndUploadImage,
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Seleccionar Imagen y Subir'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          showRawJson = !showRawJson;
                        });
                      },
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(showRawJson ? 'Ver Tabla' : 'Ver JSON Debug'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
