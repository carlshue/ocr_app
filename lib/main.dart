// 🔥 BLOQUE 1: Importaciones
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'package:path_provider/path_provider.dart';  // Para guardar temporalmente

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
  File? selectedImage;  // <--- Añade esta línea

  bool showRawJson = false;

  // 🔥 BLOQUE 4: Función para Subir Imagen y Obtener OCR
Future<void> _pickAndUploadImage() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
  if (pickedFile != null) {
    setState(() {
      selectedImage = File(pickedFile.path); // <--- Guardar imagen para mostrar
    });

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://ocrticketing-production.up.railway.app/ocr'),
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


/// Extrae manualmente los canales RGB de un color en formato ARGB (int)
int getRed(int color) => (color >> 16) & 0xFF;
int getGreen(int color) => (color >> 8) & 0xFF;
int getBlue(int color) => color & 0xFF;

/// Binariza una imagen a blanco y negro según un umbral

/// Binariza la imagen con umbral dado
img.Image binarize(img.Image src, int threshold) {
  for (int y = 0; y < src.height; y++) {
    for (int x = 0; x < src.width; x++) {
      final pixel = src.getPixel(x, y); // ← Esto es un Pixel, no un int

      final r = pixel.r;
      final g = pixel.g;
      final b = pixel.b;

      // Luminancia perceptual (Rec. 709)
      final luminance = (0.2126 * r + 0.7152 * g + 0.0722 * b).round();

      if (luminance > threshold) {
        src.setPixelRgba(x, y, 255, 255, 255, 255);
      } else {
        src.setPixelRgba(x, y, 0, 0, 0, 255);
      }
    }
  }
  return src;
}

Future<File?> _preprocessImage(File file) async {
  try {
    final bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return null;

    // Convertir a escala de grises
    img.Image gray = img.grayscale(image);

    // Binarizar con umbral 128 (llama a la función binarize que definiremos)
    img.Image binary = binarize(gray, 128);

    // Guardar imagen temporal en directorio temporal
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/preprocessed.png');
    await tempFile.writeAsBytes(img.encodePng(binary));
    return tempFile;
  } catch (e) {
    print("Error en preprocesado: $e");
    return null;
  }
}

Future<void> _pickPreprocessAndUploadImage() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
  if (pickedFile != null) {
    final preprocessedFile = await _preprocessImage(File(pickedFile.path));
    if (preprocessedFile != null) {
      setState(() {
        selectedImage = preprocessedFile; // <--- Guardar imagen procesada para mostrar
      });

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://ocrticketing-production.up.railway.app/ocr'),
      );
      request.files.add(await http.MultipartFile.fromPath('file', preprocessedFile.path));

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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error en preprocesamiento de la imagen')),
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
            // Mostrar imagen si hay
            if (selectedImage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Image.file(
                  selectedImage!,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),

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
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _pickPreprocessAndUploadImage,
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Seleccionar y Preprocesar'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
