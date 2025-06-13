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
    detectarColumnasArticuloYPrecio(); 
  }

void detectarColumnasArticuloYPrecio() {
  if (tablaEditable.isEmpty) return;
  final int columnas = tablaEditable.fold(0, (prev, row) => row.length > prev ? row.length : prev);
  final Map<int, int> posiblesPrecios = {};
  final RegExp regexPrecio = RegExp(r'^\d+([.,]\d{2})?$');
  for (int col = 0; col < columnas; col++) {
    int contador = 0;
    for (var fila in tablaEditable) {
      if (col < fila.length && regexPrecio.hasMatch(fila[col].trim())) {
        contador++;
      }
    }
    posiblesPrecios[col] = contador;
  }
  final totalFilas = tablaEditable.length;
  final mejorColumnaPrecio = posiblesPrecios.entries
      .where((e) => e.value / totalFilas >= 0.6)
      .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  if (mejorColumnaPrecio.isNotEmpty) {
    columnaPrecio = mejorColumnaPrecio.first.key;
  }
  
  for (int col = 0; col < columnas; col++) {
    if (col == columnaPrecio) continue;
    int textoCount = 0;
    for (var fila in tablaEditable) {
      if (col < fila.length && !regexPrecio.hasMatch(fila[col].trim())) {
        textoCount++;
      }
    }
    if (textoCount / totalFilas >= 0.6) {
      columnaArticulo = col;
      break;
    }
  }
}

  Widget _buildPasoSeleccionColumnas() {
    if (tablaEditable.isEmpty) return const Text("Tabla vacía");
    int columnas = tablaEditable.fold(0, (prev, row) => row.length > prev ? row.length : prev);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fondoNormal = isDark ? Colors.grey[900]! : Colors.grey[100]!;
    final fondoArticulo = Colors.orange.withOpacity(0.4);
    final fondoPrecio = Colors.blue.withOpacity(0.4);
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;
    return Expanded(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
              const Text(
                "Toca y marca las columnas ARTÍCULO y PRECIO",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("¿Qué significa PRECIO?"),
                      content: const Text(
                        "La columna PRECIO debe contener el precio total del artículo. "
                        "Por ejemplo, si tienes 'Café x4 1.20 4.80', la columna correcta sería '4.80'.",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text("Entendido"),
                        ),
                      ],
                    ),
                  );
                },
                child: const Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: fondoNormal,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black45 : Colors.grey.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Table(
                    columnWidths: {
                      for (int i = 0; i < columnas; i++) i: const IntrinsicColumnWidth(),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: List.generate(
                      tablaEditable.length.clamp(0, 5),
                      (rowIndex) {
                        final row = tablaEditable[rowIndex];
                        return TableRow(
                          children: List.generate(columnas, (colIndex) {
                            final isArticulo = columnaArticulo == colIndex;
                            final isPrecio = columnaPrecio == colIndex;
                            final cellText = (colIndex < row.length) ? row[colIndex] : "";
                            Color bgColor = fondoNormal;
                            if (isArticulo) bgColor = fondoArticulo;
                            else if (isPrecio) bgColor = fondoPrecio;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    if (columnaArticulo == colIndex) {
                                      columnaArticulo = null;
                                    } else if (columnaPrecio == colIndex) {
                                      columnaPrecio = null;
                                    } else if (columnaArticulo == null) {
                                      columnaArticulo = colIndex;
                                    } else if (columnaPrecio == null &&
                                        colIndex != columnaArticulo) {
                                      columnaPrecio = colIndex;
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    cellText,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.square, color: Colors.orangeAccent, size: 16),
                  SizedBox(width: 4),
                  Text("Columna de Artículo"),
                  SizedBox(width: 16),
                  Icon(Icons.square, color: Colors.blueAccent, size: 16),
                  SizedBox(width: 4),
                  Text("Columna de Precio"),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: (columnaArticulo != null && columnaPrecio != null)
                    ? () => setState(() => paso++)
                    : null,
                child: const Text("Siguiente"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  final _precioRegex = RegExp(r'^\d+([.,]\d{2})?$');
  Widget _buildPasoEditarTabla() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            "Edita los artículos y precios:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: tablaEditable.length,
            itemBuilder: (context, i) {
              final articuloController = TextEditingController(text: tablaEditable[i][columnaArticulo!]);
              final precioController = TextEditingController(text: tablaEditable[i][columnaPrecio!]);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: isDark ? 0 : 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: isDark ? Colors.grey[900] : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(12),
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
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final TextEditingController controller = TextEditingController();
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Introduce los nombres de los comensales",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        
        
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: "Nombre",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text("Añadir"),
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
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (personas.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: personas
                .map(
                  (p) => Chip(
                    label: Text(p.nombre),
                    backgroundColor: theme.colorScheme.secondary.withOpacity(0.2),
                    deleteIcon: const Icon(Icons.close),
                    onDeleted: () {
                      setState(() {
                        personas.remove(p);
                        consumosPorPersona.remove(p.nombre);
                      });
                    },
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          icon: const Icon(Icons.arrow_forward),
          label: const Text("Siguiente"),
          onPressed: personas.isNotEmpty
              ? () {
                  
                  
                  setState(() => paso++);
                }
              : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildPasoSeleccionarPagador() {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final controller = TextEditingController();
  final isOtraPersona = pagadorSeleccionado == "OTRA_PERSONA";
  return Expanded(
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "¿Quién ha pagado la cuenta?",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ...personas.map(
                  (p) => ChoiceChip(
                    label: Text(p.nombre),
                    selected: pagadorSeleccionado == p.nombre,
                    onSelected: (_) => setState(() {
                      pagadorSeleccionado = p.nombre;
                    }),
                  ),
                ),
                ChoiceChip(
                  label: const Text(
                    "Otra persona",
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                  selected: isOtraPersona,
                  onSelected: (_) => setState(() {
                    pagadorSeleccionado = "OTRA_PERSONA";
                  }),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (isOtraPersona)
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: "Nombre del pagador",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    pagadorSeleccionado = val.trim().isEmpty ? "OTRA_PERSONA" : val.trim();
                  });
                },
              ),
            const SizedBox(height: 24),
            
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_forward),
              label: const Text("Siguiente"),
              onPressed: (pagadorSeleccionado != null &&
                      pagadorSeleccionado!.trim().isNotEmpty &&
                      pagadorSeleccionado != "OTRA_PERSONA")
                  ? () => setState(() => paso++)
                  : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildPasoAsignarConsumo() {
  if (personas.isEmpty || columnaArticulo == null || columnaPrecio == null) {
    return const SizedBox();
  }
  final theme = Theme.of(context);
  final personaActual = personas[personaActualIndex];
  final consumosActual = consumosPorPersona[personaActual.nombre] ?? {};
  final isDark = theme.brightness == Brightness.dark;
  return Expanded(
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            "¿Qué ha consumido ${personaActual.nombre}?",
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: tablaEditable.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final descripcion = tablaEditable[index][columnaArticulo!];
              final checked = consumosActual.contains(index);
              return Card(
                color: isDark ? Colors.grey[850] : Colors.white,
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: Text(descripcion),
                  value: checked,
                  onChanged: (val) {
                    setState(() {
                      if (val) {
                        consumosPorPersona[personaActual.nombre]!.add(index);
                      } else {
                        consumosPorPersona[personaActual.nombre]!.remove(index);
                      }
                    });
                  },
                  activeColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.navigate_next),
                label: const Text("Siguiente comensal"),
                onPressed: () {
                  setState(() {
                    personaActualIndex = (personaActualIndex + 1) % personas.length;
                  });
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text("Finalizar selección"),
                onPressed: () => setState(() => paso++),
              ),
            ],
          ),
        ),
      ],
    ),
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
  
  if (pagadorSeleccionado == null || pagadorSeleccionado!.isEmpty) {
    return const Center(child: Text("Error: No se ha seleccionado pagador"));
  }
  
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
  
  Persona? pagadorPersona = personas.firstWhere(
    (p) => p.nombre.toLowerCase() == pagadorSeleccionado!.toLowerCase(),
    orElse: () => Persona(nombre: pagadorSeleccionado!),
  );
  List<Persona> personasFinal = List.from(personas);
  if (!personasFinal.any((p) => p.nombre.toLowerCase() == pagadorPersona!.nombre.toLowerCase())) {
    personasFinal.add(pagadorPersona);
  }
  
  pagos = [Pago(pagador: pagadorPersona.nombre, cantidad: totalPagado)];
  final cuenta = Cuenta(
    personas: personasFinal,
    items: items,
    pagos: pagos,
  );
  
  final deudas = calcularDeudas(cuenta);
  final theme = Theme.of(context);
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Pagador: ${pagadorPersona.nombre}",
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          "Total pagado: \$${totalPagado.toStringAsFixed(2)}",
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Text(
          "Personas que le deben dinero a ${pagadorPersona.nombre}:",
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: deudas.isEmpty
              ? Center(
                  child: Text(
                    "Nadie le debe dinero a ${pagadorPersona.nombre}",
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              : ListView(
                  children: deudas.entries
                      .where((entry) => entry.value > 0) 
                      .map((entry) {
                    final persona = entry.key;
                    final deuda = entry.value;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const Icon(Icons.person_off, color: Colors.redAccent),
                        title: Text(persona),
                        trailing: Text(
                          "\$${deuda.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
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
        ),
      ],
    ),
  );
}

Map<String, double> calcularDeudas(Cuenta cuenta) {
  final Map<String, double> deudas = {};
  if (cuenta.pagos.isEmpty) return deudas;
  final pagador = cuenta.pagos.first.pagador;
  
  final Map<String, double> consumoPorPersona = {};
  for (var item in cuenta.items) {
    final split = item.consumidores.length;
    if (split == 0) continue;
    final precioPorPersona = item.precio / split;
    for (var consumidor in item.consumidores) {
      consumoPorPersona[consumidor] = (consumoPorPersona[consumidor] ?? 0) + precioPorPersona;
    }
  }
  
  for (var persona in cuenta.personas) {
    if (persona.nombre.toLowerCase() == pagador.toLowerCase()) {
      
      continue;
    }
    final deuda = consumoPorPersona[persona.nombre] ?? 0.0;
    deudas[persona.nombre] = deuda;
  }
  return deudas;
}


@override
Widget build(BuildContext context) {
  Widget content;
  switch (paso) {
    case 0:
      content = _buildPasoSeleccionColumnas();
      break;
    case 1:
      content = _buildPasoEditarTabla();
      break;
    case 2:
      content = _buildPasoComensales();
      break;
    case 3:
      content = _buildPasoSeleccionarPagador();
      break;
    case 4:
      content = _buildPasoAsignarConsumo();
      break;
    default:
      content = _buildPasoResultado();
      break;
  }

  return Column(
    children: [
      Expanded(child: content),
    ],
  );
}

}
