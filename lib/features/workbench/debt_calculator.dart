import 'package:flutter/material.dart';
import '../../core/models/cuenta.dart';
import '../../core/models/item_consumido.dart';
import '../../core/models/persona.dart';
import '../../core/models/pago.dart';
import '../../core/services/ticket_debt_service.dart';

class CalculadoraCuentaWidget extends StatefulWidget {
  final List<List<String>> tabla;
  final void Function(Cuenta cuenta)? onCuentaFinalizada;

  const CalculadoraCuentaWidget({
    super.key,
    required this.tabla,
    this.onCuentaFinalizada,
  });

  @override
  State<CalculadoraCuentaWidget> createState() => _CalculadoraCuentaWidgetState();
}

class _CalculadoraCuentaWidgetState extends State<CalculadoraCuentaWidget> {
  int paso = 0;
  int? columnaArticulo;
  int? columnaPrecio;
  List<List<String>> tablaEditable = [];
  List<Persona> personas = [];
  Map<String, Set<int>> consumosPorPersona = {};
  List<Pago> pagos = [];
  String? pagadorSeleccionado;
  double? cantidadPagada;
  int personaActualIndex = 0;

  @override
  void initState() {
    super.initState();
    tablaEditable = List<List<String>>.from(widget.tabla);
  }

  Widget _buildPasoSeleccionColumnas() {
    if (tablaEditable.isEmpty) return const Text("Tabla vacía");

    int columnas = tablaEditable.fold(0, (prev, row) => row.length > prev ? row.length : prev);

    return Column(
      children: [
        const Text("Selecciona la columna de ARTÍCULO y PRECIO"),
        DropdownButton<int>(
          hint: const Text("Columna de artículo"),
          value: columnaArticulo,
          items: List.generate(columnas, (i) => DropdownMenuItem(value: i, child: Text("Columna ${i + 1}"))),
          onChanged: (val) => setState(() => columnaArticulo = val),
        ),
        DropdownButton<int>(
          hint: const Text("Columna de precio"),
          value: columnaPrecio,
          items: List.generate(columnas, (i) => DropdownMenuItem(value: i, child: Text("Columna ${i + 1}"))),
          onChanged: (val) => setState(() => columnaPrecio = val),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: (columnaArticulo != null && columnaPrecio != null)
              ? () => setState(() => paso++)
              : null,
          child: const Text("Siguiente"),
        )
      ],
    );
  }

final _precioRegex = RegExp(r'^\d+([.,]\d{2})?$');

Widget _buildPasoEditarTabla() {
  final _precioRegex = RegExp(r'^\d+([.,]\d{2})?$');

  return Column(
    children: [
      const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text("Edita los artículos y precios:"),
      ),
      Expanded(
        child: ListView.builder(
          itemCount: tablaEditable.length,
          itemBuilder: (context, i) {
            final articuloController = TextEditingController(text: tablaEditable[i][columnaArticulo!]);
            final precioController = TextEditingController(text: tablaEditable[i][columnaPrecio!]);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: articuloController,
                      onChanged: (val) => tablaEditable[i][columnaArticulo!] = val,
                      decoration: const InputDecoration(labelText: "Artículo"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: precioController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      onChanged: (val) => tablaEditable[i][columnaPrecio!] = val,
                      decoration: const InputDecoration(labelText: "Precio"),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() => tablaEditable.removeAt(i)),
                  )
                ],
              ),
            );
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Añadir fila"),
              onPressed: () {
                setState(() {
                  tablaEditable.add(["", ""]);
                });
              },
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                final allValid = tablaEditable.every((row) =>
                    row.length > columnaPrecio! &&
                    _precioRegex.hasMatch(row[columnaPrecio!].trim()));
                if (!allValid) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Los precios no tienen formato correcto"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                setState(() => paso++);
              },
              child: const Text("Siguiente"),
            ),
          ],
        ),
      ),
    ],
  );
}




  Widget _buildPasoComensales() {
    final controller = TextEditingController();

    return Column(
      children: [
        const Text("Introduce nombres de comensales"),
        Row(
          children: [
            Expanded(child: TextField(controller: controller)),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                final nombre = controller.text.trim();
                if (nombre.isNotEmpty) {
                  setState(() {
                    personas.add(Persona(nombre: nombre));
                    consumosPorPersona[nombre] = {};
                  });
                  controller.clear();
                }
              },
            )
          ],
        ),
        Wrap(
          spacing: 10,
          children: personas.map((p) => Chip(label: Text(p.nombre))).toList(),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: personas.isNotEmpty ? () => setState(() => paso++) : null,
          child: const Text("Siguiente"),
        )
      ],
    );
  }

Widget _buildPasoSeleccionarPagador() {
  final controller = TextEditingController();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text("¿Quién ha pagado la cuenta?"),
      DropdownButton<String>(
        isExpanded: true,
        value: pagadorSeleccionado,
        hint: const Text("Selecciona un pagador"),
        items: [
          ...personas.map((p) => DropdownMenuItem(
                value: p.nombre,
                child: Text(p.nombre),
              )),
          const DropdownMenuItem(
            value: "OTRA_PERSONA",
            child: Text("Otra persona"),
          ),
        ],
        onChanged: (val) => setState(() {
          pagadorSeleccionado = val;
        }),
      ),
      if (pagadorSeleccionado == "OTRA_PERSONA")
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              labelText: "Nombre del pagador",
            ),
            onChanged: (val) => pagadorSeleccionado = val.trim(),
          ),
        ),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: (pagadorSeleccionado != null && pagadorSeleccionado!.isNotEmpty)
            ? () => setState(() => paso++)
            : null,
        child: const Text("Siguiente"),
      ),
    ],
  );
}



  Widget _buildPasoAsignarConsumo() {
    if (personas.isEmpty || columnaArticulo == null || columnaPrecio == null) return const SizedBox();

    final personaActual = personas[personaActualIndex];

    return Column(
      children: [
        Text("¿Qué ha consumido ${personaActual.nombre}?"),
        Expanded(
          child: ListView.builder(
            itemCount: tablaEditable.length,
            itemBuilder: (context, index) {
              final descripcion = tablaEditable[index][columnaArticulo!];
              final checked = consumosPorPersona[personaActual.nombre]?.contains(index) ?? false;

              return CheckboxListTile(
                title: Text(descripcion),
                value: checked,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      consumosPorPersona[personaActual.nombre]!.add(index);
                    } else {
                      consumosPorPersona[personaActual.nombre]!.remove(index);
                    }
                  });
                },
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  personaActualIndex = (personaActualIndex + 1) % personas.length;
                });
              },
              child: const Text("Siguiente"),
            ),

            ElevatedButton(
              onPressed: () => setState(() => paso++),
              child: const Text("Finalizar selección"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasoResultado() {
    List<ItemConsumido> items = [];

    for (int i = 0; i < tablaEditable.length; i++) {
      final descripcion = tablaEditable[i][columnaArticulo!];
      final precioStr = tablaEditable[i][columnaPrecio!].replaceAll(',', '.');
      final precio = double.tryParse(precioStr) ?? 0.0;

      final consumidores = consumosPorPersona.entries
          .where((e) => e.value.contains(i))
          .map((e) => e.key)
          .toList();

      if (consumidores.isNotEmpty) {
        items.add(ItemConsumido(
            descripcion: descripcion, precio: precio, consumidores: consumidores));
      }
    }

    // Aseguramos que pagadorSeleccionado está definido
    if (pagadorSeleccionado == null || pagadorSeleccionado!.isEmpty) {
      return const Center(child: Text("Error: No se ha seleccionado pagador"));
    }

    // Calculamos el total sumando precios válidos
    double totalPagado = 0.0;
    for (var fila in tablaEditable) {
      if (columnaPrecio! < fila.length) {
        final precioStr = fila[columnaPrecio!].replaceAll(',', '.');
        final precio = double.tryParse(precioStr);
        if (precio != null && precio >= 0) {
          totalPagado += precio;
        }
      }
    }

    // Añadimos el pagador a personas si no existe
    // Buscar nombre de persona con coincidencia case insensitive
    Persona? pagadorPersona = personas.firstWhere(
      (p) => p.nombre.toLowerCase() == pagadorSeleccionado!.toLowerCase(),
      orElse: () => Persona(nombre: pagadorSeleccionado!),
    );

    List<Persona> personasFinal = List.from(personas);
    if (!personas.contains(pagadorPersona)) {
      personasFinal.add(pagadorPersona);
    }

    // Usar el nombre exacto de la persona para el pago
    pagos = [Pago(pagador: pagadorPersona.nombre, cantidad: totalPagado)];

    final cuenta = Cuenta(
      personas: personasFinal,
      items: items,
      pagos: pagos,
    );

    //debug
    print("=== Items y consumidores ===");
    for (var item in items) {
      print("${item.descripcion} - Precio: ${item.precio} - Consumidores: ${item.consumidores}");
    }

    print("=== Personas ===");
    for (var p in personasFinal) {
      print(p.nombre);
    }

    print("=== Pagos ===");
    for (var pago in pagos) {
      print("${pago.pagador} pagó ${pago.cantidad}");
    }



    final deudas = calcularDeudas(cuenta);

    return Column(
      children: [
        const Text("Resultados:"),
        Expanded(
          child: ListView(
            children: deudas.entries.map((e) {
              return ListTile(
                title: Text(e.key),
                trailing: Text(e.value.toStringAsFixed(2)),
              );
            }).toList(),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onCuentaFinalizada?.call(cuenta);
            Navigator.of(context).pop();
          },
          child: const Text("Guardar cuenta"),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (paso) {
      case 0:
        return _buildPasoSeleccionColumnas();
      case 1:
        return _buildPasoEditarTabla();
      case 2:
        return _buildPasoComensales();
      case 3:
        return _buildPasoSeleccionarPagador(); // << NUEVO PASO
      case 4:
        return _buildPasoAsignarConsumo();
      default:
        return _buildPasoResultado();
    }
  }
}
