import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/models/ticket.dart';
import '../../core/services/ticket_storage_service.dart';
import 'debt_calculator.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/ticket_debt_service.dart';

class WorkbenchPage extends StatefulWidget {
  final Ticket ticket;

  const WorkbenchPage({
    super.key,
    required this.ticket,
  });

  @override
  State<WorkbenchPage> createState() => _WorkbenchPageState();
}

class _WorkbenchPageState extends State<WorkbenchPage> {
  int _currentViewIndex = 0;
  bool _editMode = false;
  List<List<TextEditingController>> _controllers = [];

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final rows = widget.ticket.content
        .split('\n')
        .map((line) => line.split('|').map((e) => e.trim()).toList())
        .toList();
    _controllers = rows
        .map((row) => row.map((cell) => TextEditingController(text: cell)).toList())
        .toList();
  }

  Future<void> _saveEditedTable() async {
    final updatedContent = _controllers
        .map((row) => row.map((ctrl) => ctrl.text).join(' | '))
        .join('\n');

    setState(() {
      widget.ticket.content = updatedContent;
      _editMode = false;
    });

    await TicketStorageService.updateTicket(widget.ticket);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Tabla guardada correctamente.")),
    );
  }

  Future<void> _selectAndAttachImage() async {
    // Asegúrate de tener image_picker en pubspec.yaml
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        widget.ticket.imagePath = picked.path;
      });

      await TicketStorageService.updateTicket(widget.ticket);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Imagen adjuntada al ticket.")),
      );
    }
  }



  Future<void> _deleteTicket() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Seguro que quieres borrar este ticket?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Borrar')),
        ],
      ),
    );

    if (confirmed == true) {
      await TicketStorageService.deleteTicket(widget.ticket.id);
      Navigator.of(context).pop(true);
    }
  }

  Widget _buildViewContent() {
    switch (_currentViewIndex) {
      case 0:
        final hasImage = widget.ticket.imagePath != null && widget.ticket.imagePath!.isNotEmpty;
        final imageFile = hasImage ? File(widget.ticket.imagePath!) : null;

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasImage && imageFile!.existsSync())
              Image.file(imageFile, height: 200, fit: BoxFit.contain)
            else ...[
              const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text("No hay imagen disponible."),
            ],

            const SizedBox(height: 12),

            ElevatedButton.icon(
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text("Cambiar Imagen"),
              onPressed: _selectAndAttachImage,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );


    case 1:
      final maxCols = _controllers.fold<int>(
        0,
        (max, row) => row.length > max ? row.length : max,
      );

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            DataTable(
              columns: List.generate(
                maxCols + (_editMode ? 1 : 0),
                (i) {
                  if (i < maxCols) {
                    return DataColumn(
                      label: Row(
                        children: [
                          Text('[${i + 1}]', style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (_editMode)
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18),
                              onPressed: () {
                                setState(() {
                                  for (final row in _controllers) {
                                    if (i < row.length) row.removeAt(i);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                    );
                  } else {
                    return const DataColumn(label: Text(''));
                  }
                },
              ),
              rows: List.generate(_controllers.length, (rowIdx) {
                final row = _controllers[rowIdx];
                return DataRow(
                  cells: List.generate(maxCols + (_editMode ? 1 : 0), (colIdx) {
                    if (colIdx < row.length) {
                      return DataCell(
                        _editMode
                            ? SizedBox(
                                width: 100,
                                child: TextField(
                                  controller: row[colIdx],
                                  decoration: const InputDecoration(border: InputBorder.none),
                                ),
                              )
                            : Text(row[colIdx].text),
                      );
                    } else if (_editMode && colIdx == maxCols) {
                      return DataCell(
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              _controllers.removeAt(rowIdx);
                            });
                          },
                        ),
                      );
                    } else {
                      return const DataCell(Text(''));
                    }
                  }),
                );
              }),
            ),
          ],
        ),
      );


case 2:
  final cuenta = widget.ticket.cuenta;

  if (cuenta != null) {
    final pagador = cuenta.pagos.isNotEmpty ? cuenta.pagos.first.pagador : null;
    final total = cuenta.pagos.isNotEmpty ? cuenta.pagos.first.cantidad : 0.0;
    final deudas = calcularDeudas(cuenta);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Resumen de la cuenta",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text("Pagador: $pagador"),
          Text("Total pagado: \$${total.toStringAsFixed(2)}"),
          const SizedBox(height: 16),
          Text(
            "Deudas:",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...cuenta.personas.where((p) => p.nombre != pagador).map((persona) {
            final deuda = deudas[persona.nombre] ?? 0.0;
            final estaPagado = deuda <= 0;

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(
                  estaPagado ? Icons.check_circle : Icons.money_off_csred,
                  color: estaPagado ? Colors.green : Colors.redAccent,
                ),
                title: Text(persona.nombre),
                trailing: Text(
                  estaPagado ? "Pagado" : "\$${deuda.toStringAsFixed(2)}",
                  style: TextStyle(
                    color: estaPagado ? Colors.green : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 24),
          // Reemplazamos Center por Column con align center
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text("Cambiar cuenta"),
                onPressed: () {
                  final rows = widget.ticket.content
                      .split('\n')
                      .map((line) => line.split('|').map((e) => e.trim()).toList())
                      .toList();

                  print("rows: que le enviamos al calculadora cuenta \n -------- $rows  ----\n");

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CalculadoraCuentaWidget(
                        tabla: rows,
                        onCuentaFinalizada: (nuevaCuenta) async {
                          setState(() {
                            widget.ticket.cuenta = nuevaCuenta;
                          });
                          await TicketStorageService.updateTicket(widget.ticket);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Cuenta actualizada correctamente.")),
                          );
                          Navigator.of(context).pop(); // Volver al resumen
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  } else {
    // Igual quitamos el Center y usamos Column para alinear el botón
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.calculate),
            label: const Text("Crear cuenta nueva"),
            onPressed: () {
              final rows = widget.ticket.content
                  .split('\n')
                  .map((line) => line.split('|').map((e) => e.trim()).toList())
                  .toList();

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CalculadoraCuentaWidget(
                    tabla: rows,
                    onCuentaFinalizada: (cuenta) async {
                      setState(() {
                        widget.ticket.cuenta = cuenta;
                      });
                      await TicketStorageService.updateTicket(widget.ticket);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Cuenta creada correctamente.")),
                      );
                      Navigator.of(context).pop(); // Volver al resumen
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }




      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteTicket,
            tooltip: 'Borrar ticket',
          ),
        ],
        backgroundColor: Colors.black.withOpacity(0.2),
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(child: _buildViewContent()),
                BottomNavigationBar(
                  currentIndex: _currentViewIndex,
                  onTap: (index) {
                    setState(() {
                      _currentViewIndex = index;
                      if (index == 1 && !_editMode) {
                        _initControllers();
                      }
                    });
                  },
                  items: const [
                    BottomNavigationBarItem(icon: Icon(Icons.image), label: "Imagen"),
                    BottomNavigationBarItem(icon: Icon(Icons.table_chart), label: "Editar Tabla"),
                    BottomNavigationBarItem(icon: Icon(Icons.calculate), label: "Calcular Cuenta"),
                  ],
                ),
              ],
            ),
              if (_currentViewIndex == 1)
                Positioned(
                  bottom: 80,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_editMode)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FloatingActionButton.extended(
                                heroTag: "add_column",
                                onPressed: () {
                                  setState(() {
                                    for (final row in _controllers) {
                                      row.add(TextEditingController());
                                    }
                                  });
                                },
                                label: const Text('Columna'),
                                icon: const Icon(Icons.view_column),
                                backgroundColor: Colors.black.withOpacity(0.8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          if (_editMode)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FloatingActionButton.extended(
                                heroTag: "add_row",
                                onPressed: () {
                                  setState(() {
                                    final maxCols = _controllers.fold<int>(
                                      0,
                                      (max, row) => row.length > max ? row.length : max,
                                    );
                                    _controllers.add(List.generate(
                                      maxCols > 0 ? maxCols : 1,
                                      (_) => TextEditingController(),
                                    ));
                                  });
                                },
                                label: const Text('Fila'),
                                icon: const Icon(Icons.view_stream),
                                backgroundColor: Colors.black.withOpacity(0.8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          FloatingActionButton.extended(
                            heroTag: "edit_save",
                            onPressed: () {
                              if (_editMode) {
                                // Verifica tabla vacía antes de guardar
                                if (_controllers.isEmpty) {
                                  _controllers.add([TextEditingController()]);
                                } else if (_controllers.every((row) => row.isEmpty)) {
                                  _controllers = [
                                    [TextEditingController()]
                                  ];
                                }
                                _saveEditedTable();
                              } else {
                                setState(() => _editMode = true);
                              }
                            },
                            icon: Icon(_editMode ? Icons.save : Icons.edit),
                            label: Text(_editMode ? 'Guardar' : 'Editar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

          ],
        ),
      ),
    );
  }
}
