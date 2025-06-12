import '../../core/models/item_consumido.dart';
import '../../core/models/persona.dart';
import '../../core/models/pago.dart';



class Cuenta {
  final List<Persona> personas;
  final List<ItemConsumido> items;
  final List<Pago> pagos;

  Cuenta({
    required this.personas,
    required this.items,
    required this.pagos,
  });

  Map<String, dynamic> toJson() => {
        'personas': personas.map((p) => p.toJson()).toList(),
        'items': items.map((i) => i.toJson()).toList(),
        'pagos': pagos.map((p) => p.toJson()).toList(),
      };

  factory Cuenta.fromJson(Map<String, dynamic> json) => Cuenta(
        personas: (json['personas'] as List)
            .map((p) => Persona.fromJson(p))
            .toList(),
        items: (json['items'] as List)
            .map((i) => ItemConsumido.fromJson(i))
            .toList(),
        pagos: (json['pagos'] as List)
            .map((p) => Pago.fromJson(p))
            .toList(),
      );
}
