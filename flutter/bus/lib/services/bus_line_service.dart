import 'package:latlong2/latlong.dart';
import '../models/bus_line.dart';
import '../models/bus_route_recommendation.dart';
import 'api_django.dart';
import 'route_pathfinder.dart';

class BusLineService {
  static BusLineService? _instance;
  static BusLineService get instance {
    _instance ??= BusLineService._();
    return _instance!;
  }

  BusLineService._();

  List<BusLine> _lines = [];
  List<BusPoint> _points = [];
  List<LineaRuta> _lineasRutas = [];
  List<BusLinePoint> _linePoints = [];
  bool _isLoaded = false;

  Future<void> loadData() async {
    if (_isLoaded) return;

    try {
      final jsonData = await ApiService.getAllData();

      final lineasJson = jsonData['Lineas'] as List;
      _lines = lineasJson.map((json) => BusLine.fromJson(json)).toList();

      // Cargar puntos
      final puntosJson = jsonData['Puntos'] as List;
      _points = puntosJson.map((json) => BusPoint.fromJson(json)).toList();

      // Cargar rutas de líneas
      final lineaRutaJson = jsonData['LineaRuta'] as List;
      _lineasRutas = lineaRutaJson
          .map((json) => LineaRuta.fromJson(json))
          .toList();

      // Cargar líneas-puntos
      final lineasPuntosJson = jsonData['LineasPuntos'] as List;
      _linePoints = lineasPuntosJson
          .map((json) => BusLinePoint.fromJson(json))
          .toList();

      _isLoaded = true;
      print(
        '✅ Datos cargados: ${_lines.length} líneas, ${_lineasRutas.length} rutas, ${_points.length} puntos, ${_linePoints.length} puntos de ruta',
      );
    } catch (e) {
      print('❌ Error cargando datos: $e');
      rethrow;
    }
  }

  List<BusLine> getAllLines() {
    return List.unmodifiable(_lines);
  }

  BusLine? getLineById(int idLinea) {
    try {
      return _lines.firstWhere((line) => line.idLinea == idLinea);
    } catch (e) {
      return null;
    }
  }

  List<LineaRuta> getRoutesForLine(int idLinea) {
    return _lineasRutas.where((lr) => lr.idLinea == idLinea).toList();
  }

  BusRoute? getRouteById(int idLineaRuta) {
    // Buscar la información de la ruta
    final lineaRuta = _lineasRutas
        .where((lr) => lr.idLineaRuta == idLineaRuta)
        .firstOrNull;
    if (lineaRuta == null) return null;

    // Buscar la línea
    final line = getLineById(lineaRuta.idLinea);
    if (line == null) return null;

    // Buscar todos los puntos de esta ruta
    final routePoints = _linePoints
        .where((lp) => lp.idLineaRuta == idLineaRuta)
        .toList();

    if (routePoints.isEmpty) return null;

    // Ordenar por orden
    routePoints.sort((a, b) => a.orden.compareTo(b.orden));

    return BusRoute(line: line, lineaRuta: lineaRuta, points: routePoints);
  }

  List<BusRoute> getAllRoutes() {
    final routes = <BusRoute>[];
    for (final lineaRuta in _lineasRutas) {
      final route = getRouteById(lineaRuta.idLineaRuta);
      if (route != null) {
        routes.add(route);
      }
    }
    return routes;
  }

  List<BusRoute> getRoutesForBusLine(int idLinea) {
    final routes = <BusRoute>[];
    final lineasRutas = _lineasRutas.where((lr) => lr.idLinea == idLinea);
    for (final lineaRuta in lineasRutas) {
      final route = getRouteById(lineaRuta.idLineaRuta);
      if (route != null) {
        routes.add(route);
      }
    }
    return routes;
  }

  BusPoint? getPointById(int idPunto) {
    try {
      return _points.firstWhere((point) => point.idPunto == idPunto);
    } catch (e) {
      return null;
    }
  }

  List<BusLine> searchLines(String query) {
    if (query.isEmpty) return getAllLines();

    final lowerQuery = query.toLowerCase();
    return _lines.where((line) {
      return line.nombreLinea.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Encontrar las mejores opciones usando algoritmo de Dijkstra
  List<BusRouteRecommendation> findBestRoutes({
    required LatLng from,
    required LatLng to,
    int maxResults = 5,
  }) {
    final pathfinder = RoutePathfinder(getAllRoutes());
    return pathfinder.findBestRoutes(
      from: from,
      to: to,
      maxResults: maxResults,
    );
  }

  /// MÉTODO LEGACY - Mantener por compatibilidad
  BusRouteRecommendation? findBestRoute({
    required LatLng from,
    required LatLng to,
  }) {
    final routes = findBestRoutes(from: from, to: to, maxResults: 1);
    return routes.isNotEmpty ? routes.first : null;
  }
}
