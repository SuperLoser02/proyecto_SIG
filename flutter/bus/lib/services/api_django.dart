import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Cambia esta URL por la de tu servidor
  static const String baseUrl = 'http://10.0.2.2:8000/api';  // O tu IP/dominio

  static Future<Map<String, dynamic>> getAllData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/all-data/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Error al cargar datos: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en getAllData: $e');
      rethrow;
    }
  }
}