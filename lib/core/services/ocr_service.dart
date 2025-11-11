import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/ocr_word.dart';

/// Servicio para enviar los resultados del OCR al backend
/// y recibir una tabla estructurada como respuesta.
class OcrService {
  /// URL del endpoint del backend que procesa las palabras OCR
  /// y devuelve una estructura tabular en formato JSON.
  static const String apiUrl = "https://ocrticketing-production.up.railway.app/ocr-json";

  /// Envía una lista de palabras OCR al servidor y obtiene una tabla estructurada.
  ///
  /// - [words]: lista de objetos [OcrWord] extraídos de una imagen.
  ///
  /// Retorna una `Future` que resuelve con una lista de listas de strings,
  /// donde cada sublista representa una fila de la tabla.
  ///
  /// Lanza una [HttpException] si la respuesta del servidor no es exitosa.
  static Future<List<List<String>>> sendOcrWords(List<OcrWord> words) async {
    // Cuerpo del request: convierte cada OcrWord a JSON
    final payload = {
      "elements": words.map((w) => w.toJson()).toList(),
    };

    // Realiza la petición POST al backend
    final response = await http
        .post(
          Uri.parse(apiUrl),
          headers: {"Content-Type": "application/json"},
          body: json.encode(payload),
        )
        .timeout(const Duration(seconds: 10)); // Previene cuelgues largos

    // Si el servidor respondió exitosamente
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final rows = data["rows"] as List;

      // Convierte cada fila (mapa) en una lista de strings
      return rows.map<List<String>>((row) {
        return (row as Map).values.map((v) => v.toString()).toList();
      }).toList();
    } else {
      // Lanza error con el código de estado HTTP si no fue 200
      throw HttpException("Código de estado: ${response.statusCode}");
    }
  }
}
