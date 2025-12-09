import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/bus_line.dart';
import '../models/poi.dart';

/// Clase helper para crear marcadores en el mapa
class MapMarkers {
  /// Crea un marcador para la ubicación actual del usuario
  static Marker userLocationMarker(LatLng location) {
    return Marker(
      point: location,
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Círculo exterior pulsante
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
          ),
          // Círculo medio
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
          ),
          // Punto central (tu ubicación)
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Crea un marcador simple para la ubicación del usuario (versión compacta)
  static Marker userLocationMarkerCompact(LatLng location) {
    return Marker(
      point: location,
      width: 50,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Crea un marcador con etiqueta "Tú" para la ubicación del usuario
  static Marker userLocationWithLabel(LatLng location) {
    return Marker(
      point: location,
      width: 60,
      height: 60,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const Text(
            'Tú',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Crea un marcador para un destino
  static Marker destinationMarker(LatLng location, {String label = 'Destino'}) {
    return Marker(
      point: location,
      width: 60,
      height: 60,
      child: Column(
        children: [
          const Icon(Icons.place, color: Colors.red, size: 40),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Crea un marcador simple de destino sin etiqueta
  static Marker destinationMarkerSimple(LatLng location) {
    return Marker(
      point: location,
      width: 50,
      height: 50,
      child: const Icon(
        Icons.place,
        color: Colors.red,
        size: 50,
        shadows: [
          Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
    );
  }

  /// Crea un marcador para un punto de interés (POI)
  static Marker poiMarker(POI poi, {VoidCallback? onTap}) {
    return Marker(
      point: poi.location,
      width: 40,
      height: 40,
      child: GestureDetector(
        onTap: onTap,
        child: const Icon(
          Icons.location_on,
          color: Colors.red,
          size: 40,
          shadows: [
            Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
      ),
    );
  }

  /// Crea un marcador para subir a un micro (parada de inicio)
  static Marker busStartMarker(LatLng location, BusLine line) {
    return Marker(
      point: location,
      width: 80,
      height: 80,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: line.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              line.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Icon(Icons.bus_alert, color: line.color, size: 30),
          const Text('Subir', style: TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  /// Crea un marcador para bajar de un micro (parada de fin)
  static Marker busEndMarker(LatLng location, Color color) {
    return Marker(
      point: location,
      width: 60,
      height: 60,
      child: Column(
        children: [
          Icon(Icons.stop_circle, color: color, size: 30),
          const Text('Bajar', style: TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  /// Crea un marcador para punto de transbordo
  static Marker transferMarker(LatLng location) {
    return Marker(
      point: location,
      width: 80,
      height: 80,
      child: Column(
        children: [
          const Icon(
            Icons.transfer_within_a_station,
            color: Colors.orange,
            size: 30,
          ),
          const Text(
            'Transbordo',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Crea un marcador de origen con ubicación actual
  static Marker originMarker(LatLng location) {
    return Marker(
      point: location,
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
          const Icon(
            Icons.my_location,
            color: Colors.green,
            size: 30,
            shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
          ),
        ],
      ),
    );
  }

  /// Crea marcadores para inicio y fin de una ruta de micro
  static List<Marker> busRouteMarkers(BusRoute route) {
    if (route.points.isEmpty) return [];

    final firstPoint = route.points.first;
    final lastPoint = route.points.last;

    return [
      // Marcador de inicio
      Marker(
        point: firstPoint.location,
        width: 60,
        height: 60,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: route.line.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                route.line.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            Icon(Icons.play_arrow, color: route.line.color, size: 30),
          ],
        ),
      ),
      // Marcador de fin
      Marker(
        point: lastPoint.location,
        width: 50,
        height: 50,
        child: Icon(Icons.stop_circle, color: route.line.color, size: 50),
      ),
    ];
  }
}
