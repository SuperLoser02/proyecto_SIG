import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/bus_line.dart';
import '../models/bus_route_recommendation.dart';

/// Clase helper para crear polylines de rutas en el mapa
class RouteVisualizer {
  /// Crea una polyline para una ruta de caminata
  static Polyline walkingPolyline(List<LatLng> points) {
    return Polyline(
      points: points,
      color: Colors.grey,
      strokeWidth: 3.0,
      borderStrokeWidth: 1.0,
      borderColor: Colors.white,
    );
  }

  /// Crea una polyline para un segmento de transbordo
  static Polyline transferPolyline(List<LatLng> points) {
    return Polyline(
      points: points,
      color: Colors.orange,
      strokeWidth: 3.0,
      borderStrokeWidth: 1.0,
      borderColor: Colors.white,
    );
  }

  /// Crea una polyline para una ruta de micro
  static Polyline busRoutePolyline(List<LatLng> points, Color color) {
    return Polyline(points: points, color: color, strokeWidth: 5.0);
  }

  /// Crea una polyline para una ruta calculada (OSRM)
  static Polyline calculatedRoutePolyline(List<LatLng> points) {
    return Polyline(
      points: points,
      color: Colors.blue,
      strokeWidth: 5,
      borderColor: Colors.white,
      borderStrokeWidth: 2,
    );
  }

  /// Crea polylines para una recomendación de ruta directa (sin transbordo)
  static List<Polyline> directRoutePolylines({
    required LatLng userLocation,
    required LatLng destination,
    required BusRouteRecommendation recommendation,
  }) {
    return [
      // Caminata al punto de inicio del micro
      walkingPolyline([userLocation, recommendation.startPoint.location]),
      // Ruta del micro
      busRoutePolyline(
        recommendation.routeSegment,
        recommendation.route.line.color,
      ),
      // Caminata desde el punto final del micro al destino
      walkingPolyline([recommendation.endPoint.location, destination]),
    ];
  }

  /// Crea polylines para una recomendación de ruta con transbordo
  static List<Polyline> transferRoutePolylines({
    required LatLng userLocation,
    required LatLng destination,
    required BusRouteRecommendation recommendation,
  }) {
    if (!recommendation.isTransfer ||
        recommendation.transferRoute == null ||
        recommendation.transferRouteSegment == null ||
        recommendation.transferStartIndex == null ||
        recommendation.transferEndIndex == null) {
      return directRoutePolylines(
        userLocation: userLocation,
        destination: destination,
        recommendation: recommendation,
      );
    }

    return [
      // 1. Caminata al punto de inicio del primer micro
      walkingPolyline([userLocation, recommendation.startPoint.location]),

      // 2. Ruta del primer micro
      busRoutePolyline(
        recommendation.routeSegment,
        recommendation.route.line.color,
      ),

      // 3. Caminata al transbordo
      walkingPolyline([
        recommendation.endPoint.location,
        recommendation
            .transferRoute!
            .points[recommendation.transferStartIndex!]
            .location,
      ]),

      // 4. Ruta del segundo micro
      busRoutePolyline(
        recommendation.transferRouteSegment!,
        recommendation.transferRoute!.line.color,
      ),

      // 5. Caminata al destino final
      walkingPolyline([
        recommendation
            .transferRoute!
            .points[recommendation.transferEndIndex!]
            .location,
        destination,
      ]),
    ];
  }

  /// Crea polylines para mostrar una recomendación de ruta (detecta automáticamente si es transbordo)
  static List<Polyline> recommendationPolylines({
    required LatLng userLocation,
    required LatLng destination,
    required BusRouteRecommendation recommendation,
  }) {
    if (recommendation.isTransfer) {
      return transferRoutePolylines(
        userLocation: userLocation,
        destination: destination,
        recommendation: recommendation,
      );
    } else {
      return directRoutePolylines(
        userLocation: userLocation,
        destination: destination,
        recommendation: recommendation,
      );
    }
  }

  /// Crea una polyline simple para una ruta de micro completa
  static Polyline simpleBusRoutePolyline(BusRoute route) {
    return Polyline(
      points: route.coordinates,
      color: route.line.color,
      strokeWidth: 4.0,
    );
  }
}
