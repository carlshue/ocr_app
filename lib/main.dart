import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  @override
  State<OCRHomePage> createState() => _OCRHomePageState();
}

class _OCRHomePageState extends State<OCRHomePage> {
  List<dynamic> originalTexts = [];
  List<dynamic> cleanedTexts = [];
  List<dynamic> confidences = [];

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://ocrticketing-production.up.railway.app/ocr'),// ocrticketing-production.up.railway.app:8080/ocr //http://10.0.2.2:8000/ocr
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
        });
      } else {
        setState(() {
          originalTexts = [];
          cleanedTexts = [];
          confidences = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.statusCode}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OCR App')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(  // el contenido principal ocupa todo el espacio disponible arriba
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Limpio')),
                      DataColumn(label: Text('Orifinal-L33t')),
                      DataColumn(label: Text('Confianza')),
                    ],
                    rows: List<DataRow>.generate(
                      originalTexts.length,
                      (index) => DataRow(
                        cells: [
                          DataCell(Text(originalTexts[index]?.toString() ?? '')),
                          DataCell(Text(cleanedTexts[index]?.toString() ?? '')),
                          DataCell(Text(confidences[index]?.toString() ?? '')),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _pickAndUploadImage,
          child: const Text('Seleccionar Imagen y Subir'),
        ),
      ),
    );
  }
}
