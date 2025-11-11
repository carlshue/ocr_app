import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ticket.dart';
class TicketStorageService {
  static const _key = 'scanned_tickets';

  static Future<void> saveTicket(Ticket ticket) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadTickets();
    existing.add(ticket);
    final encoded = jsonEncode(existing.map((t) => t.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  static Future<List<Ticket>> loadTickets() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null) return [];
    final decoded = jsonDecode(jsonStr) as List;
    return decoded.map((e) => Ticket.fromJson(e)).toList();
  }

  static Future<void> deleteTicket(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final tickets = await loadTickets();
    tickets.removeWhere((ticket) => ticket.id == id);
    final encoded = jsonEncode(tickets.map((t) => t.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  static Future<void> updateTicket(Ticket updatedTicket) async {
    final prefs = await SharedPreferences.getInstance();
    final tickets = await loadTickets();
    final index = tickets.indexWhere((ticket) => ticket.id == updatedTicket.id);
    if (index != -1) {
      tickets[index] = updatedTicket;
      final encoded = jsonEncode(tickets.map((t) => t.toJson()).toList());
      await prefs.setString(_key, encoded);
    }
  }



}
