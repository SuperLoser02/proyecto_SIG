import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/place.dart';
import '../models/poi.dart';
import '../models/bus_line.dart';
import '../models/bus_route_recommendation.dart';
import '../utils/poi_categories.dart';

/// Clase helper para mostrar diálogos y bottom sheets del mapa
class MapDialogs {
  /// Muestra un diálogo preguntando si desea buscar rutas de micro al destino
  static Future<bool?> showBusRouteOptions(
    BuildContext context,
    Place destination,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.directions_bus, size: 48, color: Colors.orange),
        title: const Text('¿Buscar línea de micro?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Deseas buscar qué línea de micro te lleva a:',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              destination.shortName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              destination.displayName,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.search),
            label: const Text('Buscar Rutas'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Muestra un diálogo de carga mientras se buscan rutas
  static void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Obteniendo tu ubicación actual...'),
                SizedBox(height: 8),
                Text('Buscando mejor ruta de micro...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Muestra un SnackBar cuando no se encuentran rutas
  static void showNoRoutesFound(BuildContext context, LatLng from, LatLng to) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'No se encontraron rutas de micro',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Desde: ${from.latitude.toStringAsFixed(4)}, ${from.longitude.toStringAsFixed(4)}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Hacia: ${to.latitude.toStringAsFixed(4)}, ${to.longitude.toStringAsFixed(4)}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            const Text(
              'Intenta con un destino más cercano o dentro de Santa Cruz',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  /// Muestra un SnackBar con error al buscar rutas
  static void showRouteError(
    BuildContext context,
    String error,
    LatLng currentLocation,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Error al buscar rutas',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(error),
            const SizedBox(height: 4),
            Text(
              'Tu ubicación: ${currentLocation.latitude.toStringAsFixed(4)}, ${currentLocation.longitude.toStringAsFixed(4)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  /// Muestra un bottom sheet con las recomendaciones de rutas de micro
  static void showBusRouteRecommendations(
    BuildContext context, {
    required List<BusRouteRecommendation> recommendations,
    required LatLng currentLocation,
    required LatLng destination,
    required Function(BusRouteRecommendation) onRouteSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.directions_bus,
                          color: Colors.blue,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Rutas de Micro Disponibles',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.my_location,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Desde tu ubicación actual (${currentLocation.latitude.toStringAsFixed(4)}, ${currentLocation.longitude.toStringAsFixed(4)})',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.place, size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Hacia: ${destination.latitude.toStringAsFixed(4)}, ${destination.longitude.toStringAsFixed(4)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Lista de recomendaciones
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: recommendations.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final rec = recommendations[index];
                    return _buildRecommendationCard(
                      context,
                      rec,
                      onRouteSelected,
                      index + 1, // Número de opción
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye una tarjeta de recomendación
  static Widget _buildRecommendationCard(
    BuildContext context,
    BusRouteRecommendation rec,
    Function(BusRouteRecommendation) onTap,
    int optionNumber,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onTap(rec);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Número de opción y etiqueta de transbordo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Opción $optionNumber',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                  if (rec.isTransfer)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.swap_horiz,
                            size: 16,
                            color: Colors.orange.shade800,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Con Transbordo',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Líneas de micro
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: rec.route.line.color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      rec.route.line.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (rec.isTransfer && rec.transferRoute != null) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 16),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: rec.transferRoute!.line.color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        rec.transferRoute!.line.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const Divider(height: 24),
              // Detalles de distancia
              Row(
                children: [
                  const Icon(
                    Icons.directions_walk,
                    size: 20,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text('${rec.formattedWalkToStart} a pie'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.directions_bus,
                    size: 20,
                    color: rec.route.line.color,
                  ),
                  const SizedBox(width: 8),
                  Text('${rec.formattedBusDistance} en micro'),
                ],
              ),
              if (rec.isTransfer && rec.transferWalkDistance != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.transfer_within_a_station,
                      size: 20,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(rec.transferWalkDistance! < 1000 ? "${rec.transferWalkDistance!.toStringAsFixed(0)} m" : "${(rec.transferWalkDistance! / 1000).toStringAsFixed(2)} km")} transbordo',
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.directions_walk,
                    size: 20,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text('${rec.formattedWalkFromEnd} a pie'),
                ],
              ),
              const SizedBox(height: 12),
              // Total
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Distancia total:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      rec.formattedTotalDistance,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: rec.route.line.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Muestra detalles de un POI
  static void showPOIDetails(
    BuildContext context,
    POI poi,
    VoidCallback onNavigate,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              poi.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Categoría: ${poi.category}'),
            if (poi.address.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Dirección: ${poi.address}'),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onNavigate();
                    },
                    icon: const Icon(Icons.directions),
                    label: const Text('Cómo llegar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Muestra un diálogo para seleccionar categoría de POI
  static void showCategoryDialog(
    BuildContext context,
    Function(String) onCategorySelected,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buscar lugares cercanos'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: POICategory.categories.length,
            itemBuilder: (context, index) {
              final category = POICategory.categories[index];
              return ListTile(
                leading: Icon(category.icon, color: category.color),
                title: Text(category.name),
                onTap: () {
                  Navigator.pop(context);
                  onCategorySelected(category.query);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  /// Muestra un SnackBar con resumen de ruta seleccionada
  static void showRouteSelectedSnackBar(
    BuildContext context,
    BusRouteRecommendation recommendation,
  ) {
    final summaryText =
        recommendation.isTransfer && recommendation.transferRoute != null
        ? 'Camina ${recommendation.formattedWalkToStart} → ${recommendation.route.line.displayName} → Transbordo → ${recommendation.transferRoute!.line.displayName} → Camina ${recommendation.formattedWalkFromEnd}'
        : 'Camina ${recommendation.formattedWalkToStart} → ${recommendation.route.line.displayName} → Camina ${recommendation.formattedWalkFromEnd}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              recommendation.routeDescription,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(summaryText),
          ],
        ),
        duration: const Duration(seconds: 5),
        backgroundColor: recommendation.route.line.color,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  /// Muestra información de una ruta calculada (OSRM)
  static void showCalculatedRouteInfo(
    BuildContext context,
    String distance,
    String duration,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información de ruta',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.straighten),
                const SizedBox(width: 8),
                Text('Distancia: $distance'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time),
                const SizedBox(width: 8),
                Text('Duración: $duration'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Muestra un SnackBar con información de ruta de micro seleccionada
  static void showBusRouteSnackBar(BuildContext context, BusRoute route) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              route.description,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('${route.formattedDistance} • ${route.formattedTime}'),
          ],
        ),
        duration: const Duration(seconds: 4),
        backgroundColor: route.line.color,
      ),
    );
  }
}
