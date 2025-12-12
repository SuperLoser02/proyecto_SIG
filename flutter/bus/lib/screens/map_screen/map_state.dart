import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/place.dart';
import '../../models/route_info.dart';

/// Estado compartido del mapa
class MapState {
  final MapController mapController = MapController();
  final TextEditingController searchController = TextEditingController();

  LatLng currentLocation = const LatLng(-17.7833, -63.1821);
  List<Place> searchResults = [];
  RouteInfo? currentRoute;
  List<Marker> markers = [];
  List<Polyline> polylines = [];

  bool isSearching = false;
  bool isLoadingLocation = false;
  bool isSelectingOrigin = false;
  bool isSelectingDestination = false;
  LatLng? selectedOrigin;
  LatLng? selectedDestination;
  String selectedCategory = 'amenity=restaurant';

  /// Obtener el punto de origen efectivo (seleccionado o ubicación actual)
  LatLng get effectiveOrigin => selectedOrigin ?? currentLocation;

  void dispose() {
    searchController.dispose();
  }
}
