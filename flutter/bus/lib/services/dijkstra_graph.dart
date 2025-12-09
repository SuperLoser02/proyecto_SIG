import 'package:latlong2/latlong.dart';
import '../models/bus_line.dart';

/// Nodo en el grafo de rutas
class GraphNode {
  final LatLng location;
  final int? routeId;
  final int pointIndex;

  GraphNode({required this.location, this.routeId, required this.pointIndex});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GraphNode &&
          runtimeType == other.runtimeType &&
          location.latitude == other.location.latitude &&
          location.longitude == other.location.longitude &&
          routeId == other.routeId &&
          pointIndex == other.pointIndex;

  @override
  int get hashCode =>
      location.latitude.hashCode ^
      location.longitude.hashCode ^
      (routeId ?? 0).hashCode ^
      pointIndex.hashCode;
}

/// Tipo de arista en el grafo
enum EdgeType { bus, transfer }

/// Arista en el grafo de rutas
class GraphEdge {
  final GraphNode to;
  final double cost;
  final EdgeType type;
  final BusRoute? route;
  final int? startIndex;
  final int? endIndex;
  final double? walkDistance;

  GraphEdge({
    required this.to,
    required this.cost,
    required this.type,
    this.route,
    this.startIndex,
    this.endIndex,
    this.walkDistance,
  });
}

/// Entrada en la cola de prioridad
class PQEntry {
  final GraphNode node;
  final double cost;

  PQEntry({required this.node, required this.cost});
}

/// Información del camino en Dijkstra
class PathInfo {
  final GraphNode from;
  final GraphEdge edge;

  PathInfo({required this.from, required this.edge});
}

/// Resultado del algoritmo de Dijkstra
class DijkstraResult {
  final Map<GraphNode, double> distances;
  final Map<GraphNode, PathInfo> previous;

  DijkstraResult({required this.distances, required this.previous});

  /// Reconstruir el camino desde el inicio hasta el nodo objetivo
  List<GraphNode> getPath(GraphNode target) {
    final path = <GraphNode>[];
    GraphNode? current = target;

    while (current != null) {
      path.insert(0, current);
      final pathInfo = previous[current];
      current = pathInfo?.from;
    }

    return path.length > 1 ? path : [];
  }
}

/// Cola de prioridad eficiente con heap binario para Dijkstra
class PriorityQueue<T> {
  final List<T> _heap = [];
  final Comparator<T> _comparator;

  PriorityQueue(this._comparator);

  void add(T item) {
    _heap.add(item);
    _bubbleUp(_heap.length - 1);
  }

  T removeFirst() {
    if (_heap.isEmpty) throw StateError('Queue is empty');
    final first = _heap[0];
    final last = _heap.removeLast();
    if (_heap.isNotEmpty) {
      _heap[0] = last;
      _bubbleDown(0);
    }
    return first;
  }

  void _bubbleUp(int index) {
    while (index > 0) {
      final parentIndex = (index - 1) >> 1;
      if (_comparator(_heap[index], _heap[parentIndex]) >= 0) break;
      _swap(index, parentIndex);
      index = parentIndex;
    }
  }

  void _bubbleDown(int index) {
    final length = _heap.length;
    while (true) {
      final leftChild = (index << 1) + 1;
      final rightChild = leftChild + 1;
      var smallest = index;

      if (leftChild < length &&
          _comparator(_heap[leftChild], _heap[smallest]) < 0) {
        smallest = leftChild;
      }
      if (rightChild < length &&
          _comparator(_heap[rightChild], _heap[smallest]) < 0) {
        smallest = rightChild;
      }
      if (smallest == index) break;

      _swap(index, smallest);
      index = smallest;
    }
  }

  void _swap(int i, int j) {
    final temp = _heap[i];
    _heap[i] = _heap[j];
    _heap[j] = temp;
  }

  bool get isNotEmpty => _heap.isNotEmpty;
  bool get isEmpty => _heap.isEmpty;
  int get length => _heap.length;
}

/// Algoritmo de Dijkstra para encontrar caminos más cortos
class DijkstraAlgorithm {
  /// Ejecutar Dijkstra desde un nodo de inicio hacia nodos objetivo
  /// OPTIMIZADO: Se detiene cuando encuentra todos los targets
  static DijkstraResult run(
    Map<GraphNode, List<GraphEdge>> graph,
    GraphNode start,
    List<GraphNode> targets,
  ) {
    final distances = <GraphNode, double>{};
    final previous = <GraphNode, PathInfo>{};
    final pq = PriorityQueue<PQEntry>((a, b) => a.cost.compareTo(b.cost));
    final visited = <GraphNode>{};
    final targetSet = Set<GraphNode>.from(targets);
    final foundTargets = <GraphNode>{};

    // Inicializar distancias
    for (final node in graph.keys) {
      distances[node] = double.infinity;
    }
    distances[start] = 0;
    pq.add(PQEntry(node: start, cost: 0));

    while (pq.isNotEmpty) {
      final current = pq.removeFirst();

      if (visited.contains(current.node)) continue;
      visited.add(current.node);

      // Si encontramos un target, marcarlo
      if (targetSet.contains(current.node)) {
        foundTargets.add(current.node);
        
        // Si encontramos todos los targets, podemos terminar
        if (foundTargets.length >= targets.length) {
          break;
        }
      }

      final neighbors = graph[current.node] ?? [];

      for (final edge in neighbors) {
        if (visited.contains(edge.to)) continue;

        final currentDist = distances[current.node];
        if (currentDist == null) continue;

        final newDist = currentDist + edge.cost;
        final edgeToDist = distances[edge.to] ?? double.infinity;

        if (newDist < edgeToDist) {
          distances[edge.to] = newDist;
          previous[edge.to] = PathInfo(from: current.node, edge: edge);
          pq.add(PQEntry(node: edge.to, cost: newDist));
        }
      }
    }

    return DijkstraResult(distances: distances, previous: previous);
  }
}
