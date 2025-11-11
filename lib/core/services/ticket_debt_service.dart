import '../models/cuenta.dart';

Map<String, double> calcularDeudas(Cuenta cuenta) {
  final Map<String, double> debe = {};
  final Map<String, double> haPagado = {};

  // Inicializar mapas
  for (var persona in cuenta.personas) {
    debe[persona.nombre] = 0.0;
    haPagado[persona.nombre] = 0.0;
  }

  // Calcular cuánto debe cada uno según consumo
  for (var item in cuenta.items) {
    double porPersona = item.precio / item.consumidores.length;
    for (var consumidor in item.consumidores) {
      debe[consumidor] = (debe[consumidor] ?? 0) + porPersona;
    }
  }

  // Sumamos los pagos por persona, usualmente solo uno paga toda la cuenta
  for (var pago in cuenta.pagos) {
    haPagado[pago.pagador] = (haPagado[pago.pagador] ?? 0) + pago.cantidad;
  }

  // Calcular saldo final
  final Map<String, double> saldoFinal = {};
  for (var nombre in debe.keys) {
    saldoFinal[nombre] = (haPagado[nombre] ?? 0) - (debe[nombre] ?? 0);
  }

print("--- debe ---");
debe.forEach((k, v) => print("$k debe $v"));
print("--- haPagado ---");
haPagado.forEach((k, v) => print("$k ha pagado $v"));
print("--- saldoFinal ---");
saldoFinal.forEach((k, v) => print("$k saldo $v"));

  return saldoFinal; // positivo = le deben, negativo = debe
}



