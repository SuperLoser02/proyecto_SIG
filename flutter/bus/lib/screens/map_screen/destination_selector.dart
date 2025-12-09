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

    // Buscar rutas directamente sin confirmación
    onDestinationSelected(location);
  }
}
