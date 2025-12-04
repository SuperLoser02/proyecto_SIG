import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/route_info.dart';

/// Servicio para OSRM (Open Source Routing Machine)
/// Calcula rutas óptimas entre puntos
class OSRMService {
  static const String _baseUrl = 'https://router.project-osrm.org';

  /// Calcular ruta entre dos o más puntos
  /// profile: 'car', 'bike', 'foot'
  static Future<RouteInfo?> getRoute({
    required List<LatLng> waypoints,
    String profile = 'car',
    bool alternatives = false,
    bool steps = true,
  }) async {
    if (waypoints.length < 2) return null;

    try {
      // Construir coordenadas: lon,lat;lon,lat;...
      final coordinates = waypoints
          .map((point) => '${point.longitude},${point.latitude}')
          .join(';');

      final uri = Uri.parse('$_baseUrl/route/v1/$profile/$coordinates').replace(
        queryParameters: {
          'overview': 'full',
          'geometries': 'geojson',
          'alternatives': alternatives.toString(),
          'steps': steps.toString(),
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {
          return RouteInfo.fromOSRMJson(data['routes'][0]);
        }
      }

      return null;
    } catch (e) {
      // Error calculando ruta OSRM
      return null;
    }
  }

  /// Calcular ruta en coche
  static Future<RouteInfo?> getCarRoute(List<LatLng> waypoints) {
    return getRoute(waypoints: waypoints, profile: 'car');
  }

  /// Calcular ruta en bicicleta
  static Future<RouteInfo?> getBikeRoute(List<LatLng> waypoints) {
    return getRoute(waypoints: waypoints, profile: 'bike');
  }

  /// Calcular ruta caminando
  static Future<RouteInfo?> getWalkingRoute(List<LatLng> waypoints) {
    return getRoute(waypoints: waypoints, profile: 'foot');
  }

  /// Obtener duración estimada sin la geometría completa (más rápido)
  static Future<Duration?> getEstimatedDuration({
    required List<LatLng> waypoints,
    String profile = 'car',
  }) async {
    if (waypoints.length < 2) return null;

    try {
      final coordinates = waypoints
          .map((point) => '${point.longitude},${point.latitude}')
          .join(';');

      final uri = Uri.parse('$_baseUrl/route/v1/$profile/$coordinates').replace(
        queryParameters: {
          'overview': 'false',
          'steps': 'false',
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {
          final duration = data['routes'][0]['duration'] as num;
          return Duration(seconds: duration.toInt());
        }
      }

      return null;
    } catch (e) {
      // Error obteniendo duración
      return null;
    }
  }
}
