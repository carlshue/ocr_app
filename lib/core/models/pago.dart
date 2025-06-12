class Pago {
  final String pagador;
  final double cantidad;

  Pago({required this.pagador, required this.cantidad});

  Map<String, dynamic> toJson() => {
        'pagador': pagador,
        'cantidad': cantidad,
      };

  factory Pago.fromJson(Map<String, dynamic> json) => Pago(
        pagador: json['pagador'],
        cantidad: json['cantidad'],
      );
}
