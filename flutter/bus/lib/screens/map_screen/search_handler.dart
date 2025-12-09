import 'package:flutter/material.dart';
import '../../models/place.dart';
import '../../services/nominatim_service.dart';
import '../../utils/map_markers.dart';
import 'map_state.dart';

/// Manejador de búsqueda de lugares
class SearchHandler {
  final MapState state;
  final VoidCallback onUpdate;
  final Function(Place) onPlaceSelected;

  SearchHandler({
    required this.state,
    required this.onUpdate,
    required this.onPlaceSelected,
  });

  /// Buscar lugares por texto
  Future<void> searchPlaces(String query) async {
    if (query.isEmpty) {
      state.searchResults = [];
      onUpdate();
      return;
    }

    state.isSearching = true;
    onUpdate();

    final results = await NominatimService.searchPlace(query);

    state.searchResults = results;
    state.isSearching = false;
    onUpdate();
  }

  /// Seleccionar un lugar de los resultados
  void selectPlace(Place place) {
    state.searchResults = [];
    state.searchController.clear();
    state.markers = [
      MapMarkers.userLocationMarker(state.currentLocation),
      MapMarkers.destinationMarkerSimple(place.location),
    ];
    state.mapController.move(place.location, 16.0);
    onUpdate();

    Future.delayed(const Duration(milliseconds: 300), () {
      onPlaceSelected(place);
    });
  }

  /// Limpiar resultados de búsqueda
  void clearSearchResults() {
    state.searchResults = [];
    onUpdate();
  }
}
