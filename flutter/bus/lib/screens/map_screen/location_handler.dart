import 'package:flutter/material.dart';
import '../../services/location_service.dart';
import '../../utils/map_markers.dart';
import 'map_state.dart';

/// Manejador de ubicación y localización
class LocationHandler {
  final MapState state;
  final VoidCallback onUpdate;

  LocationHandler({required this.state, required this.onUpdate});

  /// Actualizar ubicación sin mover el mapa
  Future<void> updateCurrentLocation() async {
    final location = await LocationService.getCurrentLocation();
    if (location != null) {
      state.currentLocation = location;
      onUpdate();
    }
  }

  /// Obtener ubicación actual y centrar el mapa
  Future<void> getCurrentLocation() async {
    state.isLoadingLocation = true;
    onUpdate();

    final location = await LocationService.getCurrentLocation();

    if (location != null) {
      state.currentLocation = location;
      state.isLoadingLocation = false;
      state.markers = [MapMarkers.userLocationMarker(state.currentLocation)];
      state.mapController.move(state.currentLocation, 16.0);
    } else {
      state.isLoadingLocation = false;
    }
    onUpdate();
  }
}
