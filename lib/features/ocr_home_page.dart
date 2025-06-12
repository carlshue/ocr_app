import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/services/ocr_service.dart';
import '../core/services/ocr_image_processor.dart';
import '../core/models/ticket.dart';
import '../core/services/ticket_storage_service.dart';
/// Página principal de la aplicación de OCR.
///
/// Permite al usuario seleccionar una imagen desde la galería,
/// procesarla mediante ML Kit para detectar texto,
/// enviar los resultados al backend para estructurarlos como una tabla,
/// y mostrar la tabla en pantalla.
class OCRHomePage extends StatefulWidget {
  const OCRHomePage({super.key});

  @override
  State<OCRHomePage> createState() => _OCRHomePageState();
}

/// Estado interno de [OCRHomePage].
///
/// Maneja la lógica de selección de imagen, procesamiento OCR,
/// interacción con el servicio backend y visualización del resultado.
class _OCRHomePageState extends State<OCRHomePage> {
  /// Imagen seleccionada por el usuario.
  File? selectedImage;

  /// Resultado estructurado del OCR en formato tabla.
  /// Cada sublista representa una fila.
  List<List<String>> structuredTable = [];

  /// Bandera que indica si el procesamiento OCR está en curso.
  bool isProcessing = false;

  /// Permite seleccionar una imagen desde la galería y procesarla con OCR.
  ///
  /// Este método:
  /// 1. Abre el selector de imágenes.
  /// 2. Procesa la imagen con ML Kit.
  /// 3. Envía los resultados al backend para tabular.
  /// 4. Muestra la tabla en pantalla.
  ///
  /// Si ya hay un procesamiento en curso, no hace nada.
Future<void> _pickAndProcessImage() async {
  if (isProcessing) return; // Evita múltiples procesos concurrentes

  print("DEBUG: Inicio selección de imagen");

  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);

  if (pickedFile == null) {
    print("DEBUG: Usuario canceló la selección");
    return; // Usuario canceló selección
  }

  setState(() {
    selectedImage = File(pickedFile.path);
    isProcessing = true;
  });

  try {
    // Extrae texto de la imagen con ML Kit
    final ocrWords = await OcrImageProcessor.extractWords(selectedImage!);

    // Envía las palabras al backend para estructurarlas
    final table = await OcrService.sendOcrWords(ocrWords);

    setState(() {
      structuredTable = table;
    });


    //Guarda el ticket con los datos procesados
    final ticket = Ticket.newScanned(
      title: "Ticket escaneado",
      content: table.map((row) => row.join(' | ')).join('\n'),
      imagePath: selectedImage?.path,
    );
    await TicketStorageService.saveTicket(ticket);

    //_showSnackBar("✅ OCR procesado correctamente.");
  } catch (e) {
    _showErrorDialog("❌ Ocurrió un error: $e");
  } finally {
    setState(() {
      isProcessing = false;
    });
    print("DEBUG: Fin de procesamiento");
  }
}

  /// Muestra un diálogo de error con el mensaje proporcionado.
  ///
  /// [message]: texto que se mostrará en el cuerpo del diálogo.
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  /// Muestra una notificación tipo SnackBar con el mensaje dado.
  ///
  /// [message]: texto a mostrar en la barra inferior.
  //void _showSnackBar(String message) {
  //  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  //}

  /// Construye un widget de tabla basado en los datos extraídos.
  ///
  /// Retorna un `DataTable` dentro de un `SingleChildScrollView`
  /// si hay datos, o un mensaje informativo si la tabla está vacía.
  Widget buildTable() {
    if (structuredTable.isEmpty) {
      return const Center(child: Text("No hay datos para mostrar."));
    }

    // Determina la cantidad máxima de columnas entre todas las filas
    int maxCols = structuredTable.map((row) => row.length).fold(0, (a, b) => a > b ? a : b);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: List.generate(
          maxCols,
          (i) => DataColumn(label: Text("Columna ${i + 1}")),
        ),
        rows: structuredTable.map((row) {
          return DataRow(
            cells: List.generate(
              maxCols,
              (i) => DataCell(Text(i < row.length ? row[i] : '')), // Celda vacía si faltan columnas
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Construye la interfaz de usuario principal.
  ///
  /// Muestra:
  /// - La imagen seleccionada (si existe).
  /// - La tabla con los resultados OCR (si hay datos).
  /// - El botón para seleccionar una imagen.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("OCR Tabular")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Imagen seleccionada, si la hay
            if (selectedImage != null)
              Image.file(
                selectedImage!,
                height: 200,
                fit: BoxFit.contain,
              ),

            const SizedBox(height: 16),

            // Tabla de resultados
            Expanded(child: buildTable()),

            // Botón para iniciar flujo de selección/procesamiento
            ElevatedButton(
              onPressed: _pickAndProcessImage,
              child: const Text("Seleccionar Imagen"),
            ),
          ],
        ),
      ),
    );
  }
}
