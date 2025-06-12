import 'dart:ui';

/// Representa una palabra detectada por el sistema OCR.
///
/// Contiene el texto reconocido y la caja delimitadora (bounding box)
/// que indica su posición en la imagen.
class OcrWord {
  /// Texto de la palabra reconocida.
  final String text;

  /// Caja delimitadora que indica la posición de la palabra en la imagen.
  final Rect boundingBox;

  /// Crea una nueva instancia de [OcrWord].
  ///
  /// - [text]: contenido textual reconocido.
  /// - [boundingBox]: ubicación de la palabra en la imagen.
  OcrWord({required this.text, required this.boundingBox});

  /// Convierte la palabra a formato JSON para enviar al backend.
  ///
  /// Retorna un `Map<String, dynamic>` que incluye el texto y
  /// las coordenadas de la caja delimitadora.
  Map<String, dynamic> toJson() {
    return {
      "text": text,
      "boundingBox": {
        "left": boundingBox.left,
        "top": boundingBox.top,
        "right": boundingBox.right,
        "bottom": boundingBox.bottom,
      }
    };
  }
}
