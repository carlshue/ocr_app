import 'package:flutter/material.dart';
import '../core/models/ticket.dart';
import '../core/services/ticket_storage_service.dart';
import 'workbench/workbench_page.dart';

class ScannedTicketsPage extends StatefulWidget {
  const ScannedTicketsPage({super.key});

  @override
  State<ScannedTicketsPage> createState() => _ScannedTicketsPageState();
}

class _ScannedTicketsPageState extends State<ScannedTicketsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Ticket> tickets = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    final loaded = await TicketStorageService.loadTickets();
    setState(() {
      tickets = loaded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tickets Escaneados'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Listado'),
            Tab(text: 'Mapa'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTicketList(),
          const Center(child: Text('🗺️ Aquí irá el mapa con ubicaciones.')),
        ],
      ),
    );
  }

  Widget _buildTicketList() {
    if (tickets.isEmpty) {
      return const Center(child: Text('No hay tickets escaneados aún.'));
    }

    return ListView.builder(
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return ListTile(
          leading: const Icon(Icons.receipt_long),
          title: Text(ticket.title),
          subtitle: Text(
            '${ticket.scannedAt.toLocal()}',
            style: const TextStyle(fontSize: 12),
          ),
          onTap: () async {
            final deleted = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => WorkbenchPage(ticket: ticket),
              ),
            );

            if (deleted == true) {
              _loadTickets();
            }
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}