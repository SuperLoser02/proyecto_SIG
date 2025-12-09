import 'dart:async';
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
  
  Timer? _debounceTimer;
  String _lastQuery = '';
  DateTime _lastRequestTime = DateTime.now();

  SearchHandler({
    required this.state,
    required this.onUpdate,
    required this.onPlaceSelected,
  });

  /// Buscar lugares por texto con debouncing
  void searchPlaces(String query) {
    // Cancelar búsqueda anterior
    _debounceTimer?.cancel();
    
    if (query.isEmpty) {
      state.searchResults = [];
      state.isSearching = false;
      onUpdate();
      return;
    }

    // Indicar que se está buscando
    state.isSearching = true;
    onUpdate();

    // Esperar 500ms antes de buscar (debouncing)
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }
  
  /// Ejecutar la búsqueda real
  Future<void> _performSearch(String query) async {
    // Evitar búsquedas duplicadas
    if (_lastQuery == query) {
      state.isSearching = false;
      onUpdate();
      return;
    }
    
    // Respetar el límite de tasa de Nominatim (1 request/segundo)
    final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime);
    if (timeSinceLastRequest.inMilliseconds < 1000) {
      await Future.delayed(Duration(
        milliseconds: 1000 - timeSinceLastRequest.inMilliseconds,
      ));
    }
    
    _lastQuery = query;
    _lastRequestTime = DateTime.now();

    try {
      final results = await NominatimService.searchPlace(query);
      
      // Solo actualizar si todavía es la misma búsqueda
      if (_lastQuery == query) {
        state.searchResults = results;
        state.isSearching = false;
        onUpdate();
      }
    } catch (e) {
      // Manejar error
      if (_lastQuery == query) {
        state.searchResults = [];
        state.isSearching = false;
        onUpdate();
      }
    }
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
    _debounceTimer?.cancel();
    _lastQuery = '';
    state.searchResults = [];
    state.isSearching = false;
    onUpdate();
  }
  
  /// Liberar recursos
  void dispose() {
    _debounceTimer?.cancel();
  }
}
