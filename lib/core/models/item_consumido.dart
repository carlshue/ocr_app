class ItemConsumido {
  final String descripcion;
  final double precio;
  final List<String> consumidores; // nombres

  ItemConsumido({
    required this.descripcion,
    required this.precio,
    required this.consumidores,
  });

  Map<String, dynamic> toJson() => {
        'descripcion': descripcion,
        'precio': precio,
        'consumidores': consumidores,
      };

  factory ItemConsumido.fromJson(Map<String, dynamic> json) =>
      ItemConsumido(
        descripcion: json['descripcion'],
        precio: json['precio'],
        consumidores: List<String>.from(json['consumidores']),
      );
}
