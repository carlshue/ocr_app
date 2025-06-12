class Persona {
  final String nombre;

  Persona({required this.nombre});

  Map<String, dynamic> toJson() => {'nombre': nombre};

  factory Persona.fromJson(Map<String, dynamic> json) =>
      Persona(nombre: json['nombre']);
}
