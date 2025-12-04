import 'package:latlong2/latlong.dart';

/// Modelo para información de ruta (resultado de OSRM)
class RouteInfo {
  final List<LatLng> geometry;
  final double distance; // en metros
  final Duration duration;
  final List<RouteStep>? steps;

  RouteInfo({
    required this.geometry,
    required this.distance,
    required this.duration,
    this.steps,
  });

  factory RouteInfo.fromOSRMJson(Map<String, dynamic> json) {
    // Parsear geometría GeoJSON
    final List<LatLng> geometry = [];
    if (json['geometry'] != null && json['geometry']['coordinates'] != null) {
      final coordinates = json['geometry']['coordinates'] as List;
      for (var coord in coordinates) {
        geometry.add(LatLng(coord[1], coord[0])); // GeoJSON es [lon, lat]
      }
    }

    // Parsear steps si están disponibles
    List<RouteStep>? steps;
    if (json['legs'] != null && json['legs'].isNotEmpty) {
      final leg = json['legs'][0];
      if (leg['steps'] != null) {
        steps = (leg['steps'] as List)
            .map((stepJson) => RouteStep.fromOSRMJson(stepJson))
            .toList();
      }
    }

    return RouteInfo(
      geometry: geometry,
      distance: (json['distance'] as num).toDouble(),
      duration: Duration(seconds: (json['duration'] as num).toInt()),
      steps: steps,
    );
  }

  String get distanceFormatted {
    if (distance < 1000) {
      return '${distance.toInt()} m';
    }
    return '${(distance / 1000).toStringAsFixed(1)} km';
  }

  String get durationFormatted {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '$hours h $minutes min';
    }
    return '$minutes min';
  }
}

/// Modelo para un paso de la ruta
class RouteStep {
  final String instruction;
  final double distance;
  final Duration duration;
  final LatLng location;

  RouteStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.location,
  });

  factory RouteStep.fromOSRMJson(Map<String, dynamic> json) {
    return RouteStep(
      instruction: json['name'] ?? json['maneuver']?['type'] ?? '',
      distance: (json['distance'] as num).toDouble(),
      duration: Duration(seconds: (json['duration'] as num).toInt()),
      location: LatLng(
        json['maneuver']['location'][1],
        json['maneuver']['location'][0],
      ),
    );
  }
}
