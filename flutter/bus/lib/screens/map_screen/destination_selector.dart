import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../utils/map_markers.dart';
import 'map_state.dart';

/// Manejador de selección de origen y destino en el mapa
class DestinationSelector {
  final MapState state;
  final VoidCallback onUpdate;
  final BuildContext context;
  final Function(LatLng, LatLng) onRouteSearch;

  DestinationSelector({
    required this.state,
    required this.onUpdate,
    required this.context,
    required this.onRouteSearch,
  });

  /// Activar/desactivar modo de selección de origen
  void toggleOriginSelection() {
    state.isSelectingOrigin = !state.isSelectingOrigin;

    if (state.isSelectingOrigin) {
      state.isSelectingDestination = false;
      state.polylines = [];
      _updateMarkersForSelection();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.touch_app, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Toca el mapa para seleccionar tu punto de origen',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
    onUpdate();
  }

  /// Activar/desactivar modo de selección de destino
  void toggleDestinationSelection() {
    state.isSelectingDestination = !state.isSelectingDestination;

    if (state.isSelectingDestination) {
      state.isSelectingOrigin = false;
      state.polylines = [];
      _updateMarkersForSelection();

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

  /// Seleccionar ubicación en el mapa (origen o destino según el modo activo)
  void selectLocationOnMap(LatLng location) {
    if (state.isSelectingOrigin) {
      state.selectedOrigin = location;
      state.isSelectingOrigin = false;
      _updateMarkersForSelection();
      onUpdate();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Origen seleccionado'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else if (state.isSelectingDestination) {
      state.selectedDestination = location;
      state.isSelectingDestination = false;
      _updateMarkersForSelection();
      onUpdate();

      // Buscar rutas si ambos puntos están seleccionados
      if (state.selectedDestination != null) {
        onRouteSearch(state.effectiveOrigin, state.selectedDestination!);
      }
    }
  }

  /// Actualizar marcadores según los puntos seleccionados
  void _updateMarkersForSelection() {
    final markers = <Marker>[];

    // Siempre mostrar ubicación actual
    markers.add(MapMarkers.userLocationMarker(state.currentLocation));

    // Mostrar origen seleccionado si existe
    if (state.selectedOrigin != null) {
      markers.add(_createOriginMarker(state.selectedOrigin!));
    }

    // Mostrar destino seleccionado si existe
    if (state.selectedDestination != null) {
      markers.add(MapMarkers.destinationMarker(state.selectedDestination!));
    }

    state.markers = markers;
  }

  /// Crear marcador personalizado para el origen
  Marker _createOriginMarker(LatLng location) {
    return Marker(
      point: location,
      width: 50,
      height: 50,
      child: const Icon(
        Icons.trip_origin,
        color: Colors.green,
        size: 40,
        shadows: [Shadow(blurRadius: 3, color: Colors.black45)],
      ),
    );
  }

  /// Limpiar punto de origen seleccionado
  void clearOrigin() {
    state.selectedOrigin = null;
    state.polylines = [];
    _updateMarkersForSelection();
    onUpdate();
  }

  /// Limpiar punto de destino seleccionado
  void clearDestination() {
    state.selectedDestination = null;
    state.polylines = [];
    _updateMarkersForSelection();
    onUpdate();
  }
}
