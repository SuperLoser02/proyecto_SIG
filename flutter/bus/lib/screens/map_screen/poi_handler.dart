import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../models/poi.dart';
import '../../models/route_info.dart';
import '../../services/overpass_service.dart';
import '../../services/osrm_service.dart';
import '../../utils/map_dialogs.dart';
import '../../utils/map_markers.dart';
import '../../utils/route_visualizer.dart';
import 'map_state.dart';

/// Manejador de puntos de interés (POI)
class POIHandler {
  final MapState state;
  final VoidCallback onUpdate;
  final BuildContext context;

  POIHandler({
    required this.state,
    required this.onUpdate,
    required this.context,
  });

  /// Buscar POIs cercanos
  Future<void> searchNearbyPOIs() async {
    final results = await OverpassService.searchNearby(
      center: state.currentLocation,
      category: state.selectedCategory,
      radius: 3000,
    );

    state.markers = [
      MapMarkers.userLocationMarkerCompact(state.currentLocation),
      ...results.map(
        (poi) => MapMarkers.poiMarker(poi, onTap: () => showPOIDetails(poi)),
      ),
    ];
    onUpdate();
  }

  /// Mostrar detalles de un POI
  void showPOIDetails(POI poi) {
    MapDialogs.showPOIDetails(
      context,
      poi,
      () => calculateRoute(poi.location),
    );
  }

  /// Calcular ruta hacia un POI
  Future<void> calculateRoute(LatLng destination) async {
    final route = await OSRMService.getCarRoute([
      state.currentLocation,
      destination,
    ]);

    if (route != null) {
      state.currentRoute = route;
      state.polylines = [RouteVisualizer.calculatedRoutePolyline(
        route.geometry,
      )];
      state.markers = [
        MapMarkers.originMarker(state.currentLocation),
        MapMarkers.destinationMarkerSimple(destination),
      ];
      onUpdate();

      _showRouteInfo(route);
    }
  }

  /// Mostrar información de la ruta calculada
  void _showRouteInfo(RouteInfo route) {
    MapDialogs.showCalculatedRouteInfo(
      context,
      route.distanceFormatted,
      route.durationFormatted,
    );
  }
}
