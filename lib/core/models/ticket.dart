import 'package:uuid/uuid.dart';
import 'cuenta.dart'; // Asegúrate de que esta importación sea correcta
class Ticket {
  final String id;
  final String title;
  final String content;
  final DateTime scannedAt;
  final String? imagePath; // Nueva propiedad opcional
  Cuenta? cuenta; 

  Ticket({
    required this.id,
    required this.title,
    required this.content,
    required this.scannedAt,
    this.imagePath,
    this.cuenta,
  });

  factory Ticket.newScanned({
    required String title,
    required String content,
    String? imagePath,
  }) {
    return Ticket(
      id: const Uuid().v4(),
      title: title,
      content: content,
      scannedAt: DateTime.now(),
      imagePath: imagePath,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'scannedAt': scannedAt.toIso8601String(),
        'imagePath': imagePath,
        'cuenta': cuenta?.toJson(),
      };

  factory Ticket.fromJson(Map<String, dynamic> json) => Ticket(
        id: json['id'],
        title: json['title'],
        content: json['content'],
        scannedAt: DateTime.parse(json['scannedAt']),
        imagePath: json['imagePath'],
        cuenta: json['cuenta'] != null
            ? Cuenta.fromJson(json['cuenta'])
            : null,
      );
}
