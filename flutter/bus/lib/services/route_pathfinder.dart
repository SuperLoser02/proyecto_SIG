import 'package:latlong2/latlong.dart';
import '../models/bus_line.dart';
import '../models/bus_route_recommendation.dart';
import 'dijkstra_graph.dart';

/// Clase auxiliar para almacenar distancia a un nodo
class _NodeDistance {
  final GraphNode node;
  final double distance;

  _NodeDistance({required this.node, required this.distance});
}

/// Clase auxiliar para representar un segmento de ruta
class _RouteSegment {
  final BusRoute route;
  final int startIndex;
  final int endIndex;

  _RouteSegment({
    required this.route,
    required this.startIndex,
    required this.endIndex,
  });
}

/// Buscador de rutas usando algoritmo de Dijkstra
class RoutePathfinder {
  final List<BusRoute> _allRoutes;

  RoutePathfinder(this._allRoutes);

  /// Encontrar las mejores rutas desde un origen a un destino
  /// Devuelve TODAS las rutas encontradas, ordenadas de la más cercana a la más lejana
  List<BusRouteRecommendation> findBestRoutes({
    required LatLng from,
    required LatLng to,
    int maxResults = 10,
  }) {
    final Distance distance = const Distance();

    // Construir el grafo de rutas
    final graph = _buildRouteGraph(distance);

    // Encontrar nodos más cercanos al origen y destino
    final startNodes = _findNearestNodes(from, distance, maxDistance: 2000);
    final endNodes = _findNearestNodes(to, distance, maxDistance: 2000);

    if (startNodes.isEmpty || endNodes.isEmpty) {
      return [];
    }

    // Ejecutar Dijkstra desde cada nodo de inicio y recolectar TODAS las rutas
    final List<BusRouteRecommendation> allRecommendations = [];

    for (final startNode in startNodes) {
      final dijkstraResult = DijkstraAlgorithm.run(graph, startNode, endNodes);

      // Probar TODOS los nodos de destino
      for (final endNode in endNodes) {
        final path = dijkstraResult.getPath(endNode);
        if (path.isEmpty || path.length < 2) continue;

        // Convertir el camino en recomendaciones
        final recommendations = _pathToRecommendations(
          path,
          dijkstraResult,
          from,
          to,
          distance,
        );
        allRecommendations.addAll(recommendations);
      }
    }

    // Eliminar duplicados
    final uniqueRecommendations = _removeDuplicates(allRecommendations);
    
    // Ordenar por distancia total (más cercana primero)
    uniqueRecommendations.sort((a, b) {
      // Primero: menor distancia de caminata al inicio
      final walkDiff = a.walkToStartDistance.compareTo(b.walkToStartDistance);
      if (walkDiff != 0) return walkDiff;
      
      // Segundo: sin transbordo es mejor
      if (a.isTransfer != b.isTransfer) {
        return a.isTransfer ? 1 : -1;
      }
      
      // Tercero: menor distancia total
      return a.totalDistance.compareTo(b.totalDistance);
    });

    return uniqueRecommendations.take(maxResults).toList();
  }

  /// Construir grafo de conexiones entre puntos
  Map<GraphNode, List<GraphEdge>> _buildRouteGraph(Distance distance) {
    final Map<GraphNode, List<GraphEdge>> graph = {};

    for (final route in _allRoutes) {
      if (route.points.isEmpty) continue;

      // Conectar puntos consecutivos en la misma ruta (aristas de micro)
      for (int i = 0; i < route.points.length - 1; i++) {
        final currentPoint = route.points[i];
        final nextPoint = route.points[i + 1];

        final currentNode = GraphNode(
          location: currentPoint.location,
          routeId: route.lineaRuta.idLineaRuta,
          pointIndex: i,
        );

        final nextNode = GraphNode(
          location: nextPoint.location,
          routeId: route.lineaRuta.idLineaRuta,
          pointIndex: i + 1,
        );

        final dist =
            currentPoint.distancia ??
            distance.as(
              LengthUnit.Meter,
              currentPoint.location,
              nextPoint.location,
            );

        graph.putIfAbsent(currentNode, () => []);
        graph[currentNode]!.add(
          GraphEdge(
            to: nextNode,
            cost: dist * 0.1, // Factor de costo bajo para viajar en micro
            type: EdgeType.bus,
            route: route,
            startIndex: i,
            endIndex: i + 1,
          ),
        );
      }
    }

    // Agregar conexiones de transbordo entre rutas cercanas
    _addTransferEdges(graph, distance);

    return graph;
  }

  /// Agregar aristas de transbordo entre puntos cercanos de diferentes rutas
  /// OPTIMIZADO: Solo conectar puntos cercanos usando índice espacial
  void _addTransferEdges(
    Map<GraphNode, List<GraphEdge>> graph,
    Distance distance,
  ) {
    final allNodes = graph.keys.toList();
    const maxTransferDistance = 500.0; // metros

    // Usar índice espacial simple para evitar O(n²)
    // Agrupar nodos por cuadrícula
    final grid = <String, List<GraphNode>>{};
    const gridSize = 0.005; // ~500m en grados

    for (final node in allNodes) {
      final gridX = (node.location.latitude / gridSize).floor();
      final gridY = (node.location.longitude / gridSize).floor();
      
      // Agregar a la celda y celdas vecinas
      for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
          final key = '${gridX + dx},${gridY + dy}';
          grid.putIfAbsent(key, () => []).add(node);
        }
      }
    }

    final processed = <String>{};

    for (final node1 in allNodes) {
      if (node1.routeId == null) continue;

      final gridX = (node1.location.latitude / gridSize).floor();
      final gridY = (node1.location.longitude / gridSize).floor();
      final key = '$gridX,$gridY';
      
      final nearbyNodes = grid[key] ?? [];

      for (final node2 in nearbyNodes) {
        if (node2.routeId == null || node1.routeId == node2.routeId) continue;
        
        // Evitar duplicados
        final pairKey = '${node1.hashCode}-${node2.hashCode}';
        if (processed.contains(pairKey)) continue;
        processed.add(pairKey);

        final dist = distance.as(
          LengthUnit.Meter,
          node1.location,
          node2.location,
        );

        if (dist <= maxTransferDistance) {
          graph.putIfAbsent(node1, () => []);
          graph.putIfAbsent(node2, () => []);

          graph[node1]!.add(
            GraphEdge(
              to: node2,
              cost: dist * 1.5 + 300,
              type: EdgeType.transfer,
              walkDistance: dist,
            ),
          );

          graph[node2]!.add(
            GraphEdge(
              to: node1,
              cost: dist * 1.5 + 300,
              type: EdgeType.transfer,
              walkDistance: dist,
            ),
          );
        }
      }
    }
  }

  /// Encontrar nodos más cercanos a una ubicación
  /// Reducir a 10 nodos para mejor rendimiento
  List<GraphNode> _findNearestNodes(
    LatLng location,
    Distance distance, {
    double maxDistance = 2000,
  }) {
    final List<_NodeDistance> candidates = [];

    for (final route in _allRoutes) {
      for (int i = 0; i < route.points.length; i++) {
        final point = route.points[i];
        final dist = distance.as(LengthUnit.Meter, location, point.location);

        if (dist <= maxDistance) {
          candidates.add(
            _NodeDistance(
              node: GraphNode(
                location: point.location,
                routeId: route.lineaRuta.idLineaRuta,
                pointIndex: i,
              ),
              distance: dist,
            ),
          );
        }
      }
    }

    // Ordenar por distancia y tomar los 10 más cercanos
    candidates.sort((a, b) => a.distance.compareTo(b.distance));
    return candidates.take(10).map((nd) => nd.node).toList();
  }

  /// Convertir camino de Dijkstra a recomendaciones
  List<BusRouteRecommendation> _pathToRecommendations(
    List<GraphNode> path,
    DijkstraResult dijkstraResult,
    LatLng from,
    LatLng to,
    Distance distance,
  ) {
    if (path.length < 2) return [];

    // Agrupar el camino en segmentos de micro
    final segments = <_RouteSegment>[];
    BusRoute? currentRoute;
    int segmentStartIdx = 0;

    for (int i = 0; i < path.length - 1; i++) {
      final pathInfo = dijkstraResult.previous[path[i + 1]];
      if (pathInfo == null) continue;

      if (pathInfo.edge.type == EdgeType.bus) {
        final routeId = path[i].routeId;
        if (routeId == null) continue;

        if (currentRoute == null ||
            currentRoute.lineaRuta.idLineaRuta != routeId) {
          // Iniciar nuevo segmento
          if (currentRoute != null) {
            segments.add(
              _RouteSegment(
                route: currentRoute,
                startIndex: segmentStartIdx,
                endIndex: i,
              ),
            );
          }
          final route = _getRouteById(routeId);
          if (route == null) continue;
          currentRoute = route;
          segmentStartIdx = i;
        }
      } else if (pathInfo.edge.type == EdgeType.transfer) {
        // Finalizar segmento actual
        if (currentRoute != null) {
          segments.add(
            _RouteSegment(
              route: currentRoute,
              startIndex: segmentStartIdx,
              endIndex: i,
            ),
          );
          currentRoute = null;
        }
      }
    }

    // Agregar último segmento
    if (currentRoute != null) {
      segments.add(
        _RouteSegment(
          route: currentRoute,
          startIndex: segmentStartIdx,
          endIndex: path.length - 1,
        ),
      );
    }

    if (segments.isEmpty) return [];

    // Crear recomendación basada en los segmentos
    final recommendations = <BusRouteRecommendation>[];

    if (segments.length == 1) {
      // Ruta directa
      final rec = _createDirectRecommendation(
        segments[0],
        path,
        from,
        to,
        distance,
      );
      if (rec != null) recommendations.add(rec);
    } else if (segments.length >= 2) {
      // Ruta con transbordo
      final rec = _createTransferRecommendation(
        segments[0],
        segments[1],
        path,
        from,
        to,
        distance,
      );
      if (rec != null) recommendations.add(rec);
    }

    return recommendations;
  }

  /// Crear recomendación para ruta directa (sin transbordo)
  BusRouteRecommendation? _createDirectRecommendation(
    _RouteSegment segment,
    List<GraphNode> path,
    LatLng from,
    LatLng to,
    Distance distance,
  ) {
    final route = segment.route;

    // Validar índices
    final startIdx = path[segment.startIndex].pointIndex;
    final endIdx = path[segment.endIndex].pointIndex;
    if (startIdx >= route.points.length || endIdx >= route.points.length) {
      return null;
    }

    final startPoint = route.points[startIdx];
    final endPoint = route.points[endIdx];

    final walkToStart = distance.as(
      LengthUnit.Meter,
      from,
      startPoint.location,
    );
    final walkFromEnd = distance.as(LengthUnit.Meter, endPoint.location, to);

    double busDistance = 0;
    for (int i = startIdx; i < endIdx; i++) {
      if (i < route.points.length) {
        busDistance += route.points[i].distancia ?? 0;
      }
    }

    return BusRouteRecommendation(
      route: route,
      startPoint: startPoint,
      endPoint: endPoint,
      walkToStartDistance: walkToStart,
      walkFromEndDistance: walkFromEnd,
      busDistance: busDistance,
      startIndex: startIdx,
      endIndex: endIdx,
      isTransfer: false,
    );
  }

  /// Crear recomendación para ruta con transbordo
  BusRouteRecommendation? _createTransferRecommendation(
    _RouteSegment segment1,
    _RouteSegment segment2,
    List<GraphNode> path,
    LatLng from,
    LatLng to,
    Distance distance,
  ) {
    final route1 = segment1.route;
    final route2 = segment2.route;

    // Validar índices
    final start1Idx = path[segment1.startIndex].pointIndex;
    final end1Idx = path[segment1.endIndex].pointIndex;
    final start2Idx = path[segment2.startIndex].pointIndex;
    final end2Idx = path[segment2.endIndex].pointIndex;

    if (start1Idx >= route1.points.length ||
        end1Idx >= route1.points.length ||
        start2Idx >= route2.points.length ||
        end2Idx >= route2.points.length) {
      return null;
    }

    final startPoint = route1.points[start1Idx];
    final transferPoint1 = route1.points[end1Idx];
    final transferPoint2 = route2.points[start2Idx];
    final endPoint = route2.points[end2Idx];

    final walkToStart = distance.as(
      LengthUnit.Meter,
      from,
      startPoint.location,
    );
    final walkFromEnd = distance.as(LengthUnit.Meter, endPoint.location, to);
    final transferWalk = distance.as(
      LengthUnit.Meter,
      transferPoint1.location,
      transferPoint2.location,
    );

    double busDistance1 = 0;
    for (int i = start1Idx; i < end1Idx; i++) {
      if (i < route1.points.length) {
        busDistance1 += route1.points[i].distancia ?? 0;
      }
    }

    double busDistance2 = 0;
    for (int i = start2Idx; i < end2Idx; i++) {
      if (i < route2.points.length) {
        busDistance2 += route2.points[i].distancia ?? 0;
      }
    }

    return BusRouteRecommendation(
      route: route1,
      startPoint: startPoint,
      endPoint: transferPoint1,
      walkToStartDistance: walkToStart,
      walkFromEndDistance: walkFromEnd,
      busDistance: busDistance1 + busDistance2,
      startIndex: start1Idx,
      endIndex: end1Idx,
      isTransfer: true,
      transferRoute: route2,
      transferStartIndex: start2Idx,
      transferEndIndex: end2Idx,
      transferWalkDistance: transferWalk,
    );
  }

  /// Obtener ruta por ID
  BusRoute? _getRouteById(int idLineaRuta) {
    try {
      return _allRoutes.firstWhere(
        (r) => r.lineaRuta.idLineaRuta == idLineaRuta,
      );
    } catch (e) {
      return null;
    }
  }

  /// Eliminar recomendaciones duplicadas
  List<BusRouteRecommendation> _removeDuplicates(
    List<BusRouteRecommendation> recommendations,
  ) {
    final seen = <String>{};
    final unique = <BusRouteRecommendation>[];

    for (final rec in recommendations) {
      final key = rec.isTransfer
          ? '${rec.route.lineaRuta.idLineaRuta}-${rec.startIndex}-${rec.endIndex}-${rec.transferRoute?.lineaRuta.idLineaRuta}'
          : '${rec.route.lineaRuta.idLineaRuta}-${rec.startIndex}-${rec.endIndex}';

      if (!seen.contains(key)) {
        seen.add(key);
        unique.add(rec);
      }
    }

    return unique;
  }
}
