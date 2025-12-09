import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/place.dart';

/// Servicio para Nominatim - Geocoding API
/// Permite buscar lugares por nombre y hacer geocoding reverso
class NominatimService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  
  // Headers requeridos por Nominatim
  static final Map<String, String> _headers = {
    'User-Agent': 'BusApp/1.0',
  };

  /// Buscar un lugar por nombre
  /// Ejemplo: "Cine Center Santa Cruz"
  /// Devuelve una lista de lugares encontrados
  static Future<List<Place>> searchPlace(String query) async {
    if (query.isEmpty) return [];
    
    try {
      // Bounding box para Santa Cruz, Bolivia
      // Coordenadas aproximadas: [-63.25, -17.85, -63.10, -17.70]
      final uri = Uri.parse('$_baseUrl/search').replace(
        queryParameters: {
          'q': query,
          'format': 'json',
          'addressdetails': '1',
          'limit': '10',
          'bounded': '1',  // Restringir estrictamente al bounding box
          'viewbox': '-63.25,-17.85,-63.10,-17.70',  // Santa Cruz bounding box
          'countrycodes': 'bo',  // Solo Bolivia
        },
      );
      
      final response = await http.get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        // Filtrar resultados válidos
        final places = <Place>[];
        for (var json in data) {
          try {
            final place = Place.fromNominatimJson(json);
            places.add(place);
          } catch (e) {
            // Ignorar lugares con datos inválidos
            continue;
          }
        }
        
        return places;
      } else if (response.statusCode == 429) {
        // Too Many Requests - esperar y reintentar
        throw Exception('Demasiadas solicitudes. Intenta de nuevo en un momento.');
      }
      
      return [];
    } catch (e) {
      // Error en búsqueda Nominatim
      rethrow;
    }
  }

  /// Geocoding reverso: Convertir coordenadas → dirección
  static Future<String?> reverseGeocode(LatLng location) async {
    try {
      final uri = Uri.parse('$_baseUrl/reverse').replace(
        queryParameters: {
          'lat': location.latitude.toString(),
          'lon': location.longitude.toString(),
          'format': 'json',
        },
      );
      
      final response = await http.get(uri, headers: _headers);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'] as String?;
      }
      
      return null;
    } catch (e) {
      // Error en geocoding reverso
      return null;
    }
  }
}
