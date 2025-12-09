import 'package:latlong2/latlong.dart';
import '../models/bus_line.dart';

/// Recomendación de ruta de micro
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

  /// Calcular el score total (menor es mejor)
  double get totalScore {
    final walkPenalty =
        (walkToStartDistance > 800
            ? walkToStartDistance * 1.5
            : walkToStartDistance) +
        (walkFromEndDistance > 500
            ? walkFromEndDistance * 1.5
            : walkFromEndDistance);
    final transferPenalty = isTransfer
        ? (transferWalkDistance ?? 0) * 1.2 + 300
        : 0; // Penalidad por transbordo
    return walkPenalty + (busDistance * 0.1) + transferPenalty;
  }

  /// Distancia total incluyendo caminata y distancia en micro
  double get totalDistance =>
      walkToStartDistance + busDistance + walkFromEndDistance +
      (transferWalkDistance ?? 0);
      
  /// Distancia total de caminata (incluye transbordo si existe)
  double get totalWalkDistance =>
      walkToStartDistance + walkFromEndDistance + (transferWalkDistance ?? 0);

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
    return route.points
        .sublist(startIndex, endIndex + 1)
        .map((p) => p.location)
        .toList();
  }

  List<LatLng>? get transferRouteSegment {
    if (!isTransfer ||
        transferRoute == null ||
        transferStartIndex == null ||
        transferEndIndex == null) {
      return null;
    }
    return transferRoute!.points
        .sublist(transferStartIndex!, transferEndIndex! + 1)
        .map((p) => p.location)
        .toList();
  }

  String get routeDescription {
    if (isTransfer && transferRoute != null) {
      return 'Tomar ${route.line.displayName} → Transbordo → ${transferRoute!.line.displayName}';
    }
    return 'Tomar ${route.line.displayName} (${route.lineaRuta.descripcion})';
  }
}
