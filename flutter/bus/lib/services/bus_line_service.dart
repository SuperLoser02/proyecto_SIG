import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:latlong2/latlong.dart';
import '../models/bus_line.dart';
import 'api_django.dart';

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
      _lineasRutas = lineaRutaJson.map((json) => LineaRuta.fromJson(json)).toList();

      // Cargar líneas-puntos
      final lineasPuntosJson = jsonData['LineasPuntos'] as List;
      _linePoints = lineasPuntosJson.map((json) => BusLinePoint.fromJson(json)).toList();


      _isLoaded = true;
      print('✅ Datos cargados: ${_lines.length} líneas, ${_lineasRutas.length} rutas, ${_points.length} puntos, ${_linePoints.length} puntos de ruta');
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
    final lineaRuta = _lineasRutas.where((lr) => lr.idLineaRuta == idLineaRuta).firstOrNull;
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

    return BusRoute(
      line: line,
      lineaRuta: lineaRuta,
      points: routePoints,
    );
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

  // Encontrar la mejor ruta de micro para ir de un punto A a un punto B
  BusRouteRecommendation? findBestRoute({
    required LatLng from,
    required LatLng to,
  }) {
    final Distance distance = const Distance();
    BusRouteRecommendation? bestRecommendation;
    double bestScore = double.infinity;

    for (final route in getAllRoutes()) {
      if (route.points.isEmpty) continue;

      // Encontrar el punto más cercano al origen
      double minDistanceToStart = double.infinity;
      BusLinePoint? closestStartPoint;
      int startIndex = 0;

      for (int i = 0; i < route.points.length; i++) {
        final point = route.points[i];
        final dist = distance.as(
          LengthUnit.Meter,
          from,
          point.location,
        );
        if (dist < minDistanceToStart) {
          minDistanceToStart = dist;
          closestStartPoint = point;
          startIndex = i;
        }
      }

      // Encontrar el punto más cercano al destino (después del punto de inicio)
      double minDistanceToEnd = double.infinity;
      BusLinePoint? closestEndPoint;
      int endIndex = startIndex;

      for (int i = startIndex; i < route.points.length; i++) {
        final point = route.points[i];
        final dist = distance.as(
          LengthUnit.Meter,
          to,
          point.location,
        );
        if (dist < minDistanceToEnd) {
          minDistanceToEnd = dist;
          closestEndPoint = point;
          endIndex = i;
        }
      }

      if (closestStartPoint == null || closestEndPoint == null || endIndex <= startIndex) {
        continue;
      }

      // Calcular distancia caminando al punto de inicio
      final walkToStart = minDistanceToStart;
      
      // Calcular distancia caminando desde el punto final
      final walkFromEnd = minDistanceToEnd;

      // Calcular distancia en el micro
      double busDistance = 0;
      for (int i = startIndex; i < endIndex; i++) {
        busDistance += route.points[i].distancia ?? 0.0;
      }

      // Score: priorizar menos caminata y distancia razonable en micro
      // Penalizar si hay que caminar más de 500m al inicio o 300m al final
      final walkPenalty = (walkToStart > 500 ? walkToStart * 2 : walkToStart) +
                          (walkFromEnd > 300 ? walkFromEnd * 2 : walkFromEnd);
      final score = walkPenalty + (busDistance * 0.1);

      if (score < bestScore && walkToStart < 1000 && walkFromEnd < 800) {
        bestScore = score;
        bestRecommendation = BusRouteRecommendation(
          route: route,
          startPoint: closestStartPoint,
          endPoint: closestEndPoint,
          walkToStartDistance: walkToStart,
          walkFromEndDistance: walkFromEnd,
          busDistance: busDistance,
          startIndex: startIndex,
          endIndex: endIndex,
        );
      }
    }

    return bestRecommendation;
  }

  // Encontrar las mejores opciones (incluyendo rutas directas y con transbordo)
  List<BusRouteRecommendation> findBestRoutes({
    required LatLng from,
    required LatLng to,
    int maxResults = 5,
  }) {
    final Distance distance = const Distance();
    final List<BusRouteRecommendation> recommendations = [];

    // 1. Buscar rutas directas (1 solo micro)
    for (final route in getAllRoutes()) {
      if (route.points.isEmpty) continue;

      // Encontrar el punto más cercano al origen
      double minDistanceToStart = double.infinity;
      BusLinePoint? closestStartPoint;
      int startIndex = 0;

      for (int i = 0; i < route.points.length; i++) {
        final point = route.points[i];
        final dist = distance.as(
          LengthUnit.Meter,
          from,
          point.location,
        );
        if (dist < minDistanceToStart) {
          minDistanceToStart = dist;
          closestStartPoint = point;
          startIndex = i;
        }
      }

      // Encontrar el punto más cercano al destino (después del punto de inicio)
      double minDistanceToEnd = double.infinity;
      BusLinePoint? closestEndPoint;
      int endIndex = startIndex;

      for (int i = startIndex; i < route.points.length; i++) {
        final point = route.points[i];
        final dist = distance.as(
          LengthUnit.Meter,
          to,
          point.location,
        );
        if (dist < minDistanceToEnd) {
          minDistanceToEnd = dist;
          closestEndPoint = point;
          endIndex = i;
        }
      }

      if (closestStartPoint == null || closestEndPoint == null || endIndex <= startIndex) {
        continue;
      }

      final walkToStart = minDistanceToStart;
      final walkFromEnd = minDistanceToEnd;

      // Aumentar límites de caminata: 2km inicio, 1.5km final
      if (walkToStart > 2000 || walkFromEnd > 1500) {
        continue;
      }

      double busDistance = 0;
      for (int i = startIndex; i < endIndex; i++) {
        busDistance += route.points[i].distancia ?? 0.0;
      }

      // Solo agregar si el micro realmente acerca al destino
      if (busDistance > 100) {
        recommendations.add(BusRouteRecommendation(
          route: route,
          startPoint: closestStartPoint,
          endPoint: closestEndPoint,
          walkToStartDistance: walkToStart,
          walkFromEndDistance: walkFromEnd,
          busDistance: busDistance,
          startIndex: startIndex,
          endIndex: endIndex,
          isTransfer: false,
        ));
      }
    }

    // 2. Buscar rutas con transbordo (2 micros)
    final transferRecommendations = _findTransferRoutes(from, to, distance);
    recommendations.addAll(transferRecommendations);

    // Ordenar por score
    recommendations.sort((a, b) {
      final scoreA = a.totalScore;
      final scoreB = b.totalScore;
      return scoreA.compareTo(scoreB);
    });

    return recommendations.take(maxResults).toList();
  }

  // Encontrar rutas con transbordo (tomar 2 micros)
  List<BusRouteRecommendation> _findTransferRoutes(
    LatLng from,
    LatLng to,
    Distance distance,
  ) {
    final List<BusRouteRecommendation> transferRoutes = [];
    final allRoutes = getAllRoutes();

    // Probar combinaciones de 2 rutas (limitar para evitar demoras)
    for (int i = 0; i < allRoutes.length && i < 15; i++) {
      final route1 = allRoutes[i];
      if (route1.points.isEmpty) continue;

      // Encontrar mejor punto de inicio en ruta 1
      double minDistToStart1 = double.infinity;
      int startIdx1 = 0;
      for (int j = 0; j < route1.points.length; j++) {
        final dist = distance.as(LengthUnit.Meter, from, route1.points[j].location);
        if (dist < minDistToStart1) {
          minDistToStart1 = dist;
          startIdx1 = j;
        }
      }

      if (minDistToStart1 > 2000) continue; // Máximo 2km de caminata inicial

      // Probar puntos de bajada en ruta 1 (cada 5 puntos para eficiencia)
      for (int endIdx1 = startIdx1 + 5; endIdx1 < route1.points.length; endIdx1 += 3) {
        final transferPoint = route1.points[endIdx1].location;

        // Buscar ruta 2 que conecte desde el punto de transbordo
        for (int k = 0; k < allRoutes.length && k < 15; k++) {
          if (k == i) continue; // No usar la misma ruta
          final route2 = allRoutes[k];
          if (route2.points.isEmpty) continue;

          // Encontrar punto más cercano al transbordo en ruta 2
          double minDistToTransfer = double.infinity;
          int startIdx2 = 0;
          for (int j = 0; j < route2.points.length; j++) {
            final dist = distance.as(LengthUnit.Meter, transferPoint, route2.points[j].location);
            if (dist < minDistToTransfer) {
              minDistToTransfer = dist;
              startIdx2 = j;
            }
          }

          if (minDistToTransfer > 500) continue; // Máximo 500m de caminata entre micros

          // Encontrar punto más cercano al destino en ruta 2
          double minDistToEnd = double.infinity;
          int endIdx2 = startIdx2;
          for (int j = startIdx2; j < route2.points.length; j++) {
            final dist = distance.as(LengthUnit.Meter, to, route2.points[j].location);
            if (dist < minDistToEnd) {
              minDistToEnd = dist;
              endIdx2 = j;
            }
          }

          if (endIdx2 <= startIdx2 || minDistToEnd > 1500) continue;

          // Calcular distancias
          double busDist1 = 0;
          for (int j = startIdx1; j < endIdx1; j++) {
            busDist1 += route1.points[j].distancia ?? 0.0;
          }

          double busDist2 = 0;
          for (int j = startIdx2; j < endIdx2; j++) {
            busDist2 += route2.points[j].distancia ?? 0.0;
          }

          final totalBusDist = busDist1 + busDist2;
          if (totalBusDist < 500) continue; // Debe valer la pena el transbordo

          transferRoutes.add(BusRouteRecommendation(
            route: route1,
            startPoint: route1.points[startIdx1],
            endPoint: route1.points[endIdx1],
            walkToStartDistance: minDistToStart1,
            walkFromEndDistance: minDistToEnd,
            busDistance: totalBusDist,
            startIndex: startIdx1,
            endIndex: endIdx1,
            isTransfer: true,
            transferRoute: route2,
            transferStartIndex: startIdx2,
            transferEndIndex: endIdx2,
            transferWalkDistance: minDistToTransfer,
          ));
        }
      }
    }

    return transferRoutes;
  }
}

class BusRouteRecommendation {
  final BusRoute route;
  final BusLinePoint startPoint;
  final BusLinePoint endPoint;
  final double walkToStartDistance;
  final double walkFromEndDistance;
  final double busDistance;
  final int startIndex;
  final int endIndex;
  final bool isTransfer;
  final BusRoute? transferRoute;
  final int? transferStartIndex;
  final int? transferEndIndex;
  final double? transferWalkDistance;

  BusRouteRecommendation({
    required this.route,
    required this.startPoint,
    required this.endPoint,
    required this.walkToStartDistance,
    required this.walkFromEndDistance,
    required this.busDistance,
    required this.startIndex,
    required this.endIndex,
    this.isTransfer = false,
    this.transferRoute,
    this.transferStartIndex,
    this.transferEndIndex,
    this.transferWalkDistance,
  });

  double get totalScore {
    final walkPenalty = (walkToStartDistance > 800 ? walkToStartDistance * 1.5 : walkToStartDistance) +
                        (walkFromEndDistance > 500 ? walkFromEndDistance * 1.5 : walkFromEndDistance);
    final transferPenalty = isTransfer ? (transferWalkDistance ?? 0) * 1.2 + 300 : 0; // Penalidad por transbordo
    return walkPenalty + (busDistance * 0.1) + transferPenalty;
  }

  double get totalDistance => walkToStartDistance + busDistance + walkFromEndDistance;

  String get formattedWalkToStart {
    if (walkToStartDistance < 1000) {
      return '${walkToStartDistance.toStringAsFixed(0)} m';
    }
    return '${(walkToStartDistance / 1000).toStringAsFixed(2)} km';
  }

  String get formattedWalkFromEnd {
    if (walkFromEndDistance < 1000) {
      return '${walkFromEndDistance.toStringAsFixed(0)} m';
    }
    return '${(walkFromEndDistance / 1000).toStringAsFixed(2)} km';
  }

  String get formattedBusDistance {
    if (busDistance < 1000) {
      return '${busDistance.toStringAsFixed(0)} m';
    }
    return '${(busDistance / 1000).toStringAsFixed(2)} km';
  }

  String get formattedTotalDistance {
    if (totalDistance < 1000) {
      return '${totalDistance.toStringAsFixed(0)} m';
    }
    return '${(totalDistance / 1000).toStringAsFixed(2)} km';
  }

  List<LatLng> get routeSegment {
    return route.points.sublist(startIndex, endIndex + 1).map((p) => p.location).toList();
  }

  List<LatLng>? get transferRouteSegment {
    if (!isTransfer || transferRoute == null || transferStartIndex == null || transferEndIndex == null) {
      return null;
    }
    return transferRoute!.points.sublist(transferStartIndex!, transferEndIndex! + 1).map((p) => p.location).toList();
  }

  String get routeDescription {
    if (isTransfer && transferRoute != null) {
      return 'Tomar ${route.line.displayName} → Transbordo → ${transferRoute!.line.displayName}';
    }
    return 'Tomar ${route.line.displayName} (${route.lineaRuta.descripcion})';
  }
}
