import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/models/ticket.dart';
import '../../core/services/ticket_storage_service.dart';
import 'debt_calculator.dart';

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
  int _currentViewIndex = 0; // 0: imagen, 1: tabla, 2: calcular

  void _onSwipe(DragEndDetails details) {
    Navigator.of(context).pop(); // Swipe para salir
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
      Navigator.of(context).pop(true); // Cierra la pantalla tras borrar
    }
  }

  Widget _buildViewContent() {
    switch (_currentViewIndex) {
      case 0:
        if (widget.ticket.imagePath != null && widget.ticket.imagePath!.isNotEmpty) {
          final imageFile = File(widget.ticket.imagePath!);
          if (imageFile.existsSync()) {
            return Image.file(imageFile);
          } else {
            return const Center(child: Text("La imagen no está disponible."));
          }
        } else {
          return const Center(child: Text("No hay imagen disponible."));
        }
      case 1:
        final rows = widget.ticket.content.split('\n').map((line) => line.split('|')).toList();
        final maxCols = rows.fold<int>(0, (max, row) => row.length > max ? row.length : max);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: List.generate(
              maxCols,
              (i) => DataColumn(label: Text('Columna ${i + 1}')),
            ),
            rows: rows
                .map((row) => DataRow(
                      cells: List.generate(
                        maxCols,
                        (i) => DataCell(Text(i < row.length ? row[i].trim() : '')),
                      ),
                    ))
                .toList(),
          ),
        );
    case 2:
      final rows = widget.ticket.content
          .split('\n')
          .map((line) => line.split('|').map((e) => e.trim()).toList())
          .toList();

      return CalculadoraCuentaWidget(
        tabla: rows,
        onCuentaFinalizada: (cuenta) async {
          setState(() {
            widget.ticket.cuenta = cuenta;
          });

          await TicketStorageService.updateTicket(widget.ticket);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Cuenta actualizada correctamente.")),
          );
        },
      );
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
        child: Column(
          children: [
            Expanded(child: _buildViewContent()),
            BottomNavigationBar(
              currentIndex: _currentViewIndex,
              onTap: (index) => setState(() => _currentViewIndex = index),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.image), label: "Imagen"),
                BottomNavigationBarItem(icon: Icon(Icons.table_chart), label: "Editar Tabla"),
                BottomNavigationBarItem(icon: Icon(Icons.calculate), label: "Calcular Cuenta"),
              ],
            )
          ],
        ),
      ),
    );
  }
}
