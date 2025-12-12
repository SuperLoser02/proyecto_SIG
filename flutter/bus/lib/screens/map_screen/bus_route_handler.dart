import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/bus_line.dart';
import '../../models/bus_route_recommendation.dart';
import '../../services/bus_line_service.dart';
import '../../utils/map_dialogs.dart';
import '../../utils/map_markers.dart';
import '../../utils/route_visualizer.dart';
import 'map_state.dart';

/// Manejador de rutas de micro
class BusRouteHandler {
  final MapState state;
  final VoidCallback onUpdate;
  final BuildContext context;

  BusRouteHandler({
    required this.state,
    required this.onUpdate,
    required this.context,
  });

  /// Buscar rutas de micro hacia un destino
  Future<void> findBusRouteTo(LatLng origin, LatLng destination) async {
    MapDialogs.showLoadingDialog(context);

    try {
      await BusLineService.instance.loadData();

      // Ejecutar la búsqueda en un compute isolate para no bloquear la UI
      final recommendations = await BusLineService.instance.findBestRoutes(
        from: origin,
        to: destination,
        maxResults: 10,
      );

      if (!context.mounted) return;
      Navigator.pop(context);

      if (recommendations.isEmpty) {
        MapDialogs.showNoRoutesFound(context, origin, destination);
        return;
      }

      MapDialogs.showBusRouteRecommendations(
        context,
        recommendations: recommendations,
        currentLocation: origin,
        destination: destination,
        onRouteSelected: (rec) =>
            showRecommendedRoute(rec, origin, destination),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      MapDialogs.showRouteError(context, e.toString(), origin);
    }
  }

  /// Mostrar ruta recomendada en el mapa
  void showRecommendedRoute(
    BusRouteRecommendation recommendation,
    LatLng origin,
    LatLng destination,
  ) {
    state.currentRoute = null;
    state.polylines = RouteVisualizer.recommendationPolylines(
      userLocation: origin,
      destination: destination,
      recommendation: recommendation,
    );

    state.markers = [
      MapMarkers.userLocationWithLabel(origin),
      MapMarkers.busStartMarker(
        recommendation.startPoint.location,
        recommendation.route.line,
      ),
      if (recommendation.isTransfer &&
          recommendation.transferRoute != null) ...[
        MapMarkers.transferMarker(recommendation.endPoint.location),
        MapMarkers.busStartMarker(
          recommendation
              .transferRoute!
              .points[recommendation.transferStartIndex!]
              .location,
          recommendation.transferRoute!.line,
        ),
        MapMarkers.busEndMarker(
          recommendation
              .transferRoute!
              .points[recommendation.transferEndIndex!]
              .location,
          recommendation.transferRoute!.line.color,
        ),
      ] else
        MapMarkers.busEndMarker(
          recommendation.endPoint.location,
          recommendation.route.line.color,
        ),
      MapMarkers.destinationMarker(destination),
    ];

    final allPoints = [
      origin,
      ...recommendation.routeSegment,
      if (recommendation.isTransfer &&
          recommendation.transferRouteSegment != null)
        ...recommendation.transferRouteSegment!,
      destination,
    ];

    state.mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(allPoints),
        padding: const EdgeInsets.all(50),
      ),
    );

    onUpdate();
    MapDialogs.showRouteSelectedSnackBar(context, recommendation);
  }

  /// Mostrar ruta de micro seleccionada desde la lista
  void showBusRoute(BusRoute busRoute) {
    state.currentRoute = null;
    state.polylines = [RouteVisualizer.simpleBusRoutePolyline(busRoute)];

    if (busRoute.points.isNotEmpty) {
      state.markers = MapMarkers.busRouteMarkers(busRoute);
      state.mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(busRoute.coordinates),
          padding: const EdgeInsets.all(50),
        ),
      );
    }

    onUpdate();
    MapDialogs.showBusRouteSnackBar(context, busRoute);
  }
}
