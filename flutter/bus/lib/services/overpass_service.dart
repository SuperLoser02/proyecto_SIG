import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/poi.dart';

/// Servicio para Overpass API
/// Permite buscar POIs (Points of Interest) cercanos en Santa Cruz, Bolivia
class OverpassService {
  static const String _baseUrl = 'https://overpass-api.de/api/interpreter';
  
  // Bounding box de Santa Cruz, Bolivia (Oeste, Sur, Este, Norte)
  static const double _santaCruzSouth = -18.0500;
  static const double _santaCruzWest = -63.3500;
  static const double _santaCruzNorth = -17.5000;
  static const double _santaCruzEast = -62.9000;

  /// Buscar lugares cercanos por categoría dentro de Santa Cruz
  /// Ejemplos: amenity=pharmacy (farmacias), amenity=restaurant, amenity=bus_station
  /// radius en metros (máximo 5km para optimizar búsqueda)
  static Future<List<POI>> searchNearby({
    required LatLng center,
    required String category,
    double radius = 1000,
  }) async {
    try {
      // Limitar radio máximo a 5km para Santa Cruz
      final effectiveRadius = radius > 5000 ? 5000 : radius;
      
      // Construir query de Overpass con bounding box de Santa Cruz
      final query = '''
        [out:json][timeout:25][bbox:$_santaCruzSouth,$_santaCruzWest,$_santaCruzNorth,$_santaCruzEast];
        (
          node["$category"](around:$effectiveRadius,${center.latitude},${center.longitude});
          way["$category"](around:$effectiveRadius,${center.latitude},${center.longitude});
          relation["$category"](around:$effectiveRadius,${center.latitude},${center.longitude});
        );
        out body;
        >;
        out skel qt;
      ''';

      final response = await http.post(
        Uri.parse(_baseUrl),
        body: {'data': query},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List;
        
        return elements
            .where((e) => e['lat'] != null && e['lon'] != null)
            .map((json) => POI.fromOverpassJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      // Error en búsqueda Overpass
      return [];
    }
  }

  /// Categorías predefinidas comunes
  static Future<List<POI>> searchRestaurants(LatLng center, {double radius = 1000}) {
    return searchNearby(center: center, category: 'amenity=restaurant', radius: radius);
  }

  static Future<List<POI>> searchPharmacies(LatLng center, {double radius = 1000}) {
    return searchNearby(center: center, category: 'amenity=pharmacy', radius: radius);
  }

  static Future<List<POI>> searchBusStops(LatLng center, {double radius = 1000}) {
    return searchNearby(center: center, category: 'highway=bus_stop', radius: radius);
  }

  static Future<List<POI>> searchATMs(LatLng center, {double radius = 1000}) {
    return searchNearby(center: center, category: 'amenity=atm', radius: radius);
  }

  static Future<List<POI>> searchHospitals(LatLng center, {double radius = 1000}) {
    return searchNearby(center: center, category: 'amenity=hospital', radius: radius);
  }

  static Future<List<POI>> searchSupermarkets(LatLng center, {double radius = 1000}) {
    return searchNearby(center: center, category: 'shop=supermarket', radius: radius);
  }
}
