import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../utils/map_markers.dart';
import 'map_state.dart';

/// Manejador de selección de destino en el mapa
class DestinationSelector {
  final MapState state;
  final VoidCallback onUpdate;
  final BuildContext context;
  final Function(LatLng) onDestinationSelected;

  DestinationSelector({
    required this.state,
    required this.onUpdate,
    required this.context,
    required this.onDestinationSelected,
  });

  /// Activar/desactivar modo de selección
  void toggleSelectionMode() {
    state.isSelectingDestination = !state.isSelectingDestination;

    if (state.isSelectingDestination) {
      state.selectedDestination = null;
      state.polylines = [];
      state.markers = [MapMarkers.userLocationMarker(state.currentLocation)];

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.touch_app, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Toca el mapa para seleccionar tu destino',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 3),
        ),
      );
    }
    onUpdate();
  }

  /// Seleccionar destino en el mapa
  void selectDestinationOnMap(LatLng location) {
    state.selectedDestination = location;
    state.isSelectingDestination = false;
    state.markers = [
      MapMarkers.userLocationMarker(state.currentLocation),
      MapMarkers.destinationMarker(location),
    ];
    onUpdate();

    _showConfirmationDialog(location);
  }

  /// Mostrar diálogo de confirmación
  Future<void> _showConfirmationDialog(LatLng destination) async {
    final shouldSearch = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_on, color: Colors.red),
            SizedBox(width: 8),
            Text('Destino Seleccionado'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Buscar rutas de micro hacia este destino?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.pin_drop, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lat: ${destination.latitude.toStringAsFixed(5)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.pin_drop, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lng: ${destination.longitude.toStringAsFixed(5)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
            icon: const Icon(Icons.directions_bus),
            label: const Text('Buscar Rutas'),
          ),
        ],
      ),
    );

    if (shouldSearch == true && context.mounted) {
      onDestinationSelected(destination);
    }
  }
}
