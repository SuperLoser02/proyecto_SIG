import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/place.dart';
import '../models/bus_line.dart';
import '../utils/map_dialogs.dart';
import 'bus_lines_screen.dart';
import 'map_screen/map_state.dart';
import 'map_screen/location_handler.dart';
import 'map_screen/search_handler.dart';
import 'map_screen/bus_route_handler.dart';
import 'map_screen/destination_selector.dart';
import 'map_screen/poi_handler.dart';
import 'map_screen/map_widgets.dart' as widgets;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapState _state;
  late final LocationHandler _locationHandler;
  late final SearchHandler _searchHandler;
  late final BusRouteHandler _busRouteHandler;
  late final DestinationSelector _destinationSelector;
  late final POIHandler _poiHandler;

  @override
  void initState() {
    super.initState();
    _state = MapState();
    _initializeHandlers();
    _locationHandler.getCurrentLocation();
  }

  void _initializeHandlers() {
    _locationHandler = LocationHandler(
      state: _state,
      onUpdate: () => setState(() {}),
    );

    _searchHandler = SearchHandler(
      state: _state,
      onUpdate: () => setState(() {}),
      onPlaceSelected: _showBusRouteOptions,
    );

    _busRouteHandler = BusRouteHandler(
      state: _state,
      onUpdate: () => setState(() {}),
      context: context,
    );

    _destinationSelector = DestinationSelector(
      state: _state,
      onUpdate: () => setState(() {}),
      context: context,
      onDestinationSelected: _busRouteHandler.findBusRouteTo,
    );

    _poiHandler = POIHandler(
      state: _state,
      onUpdate: () => setState(() {}),
      context: context,
    );
  }

  Future<void> _showBusRouteOptions(Place destination) async {
    // Mostrar diálogo de confirmación para búsqueda por texto
    final shouldSearch = await MapDialogs.showBusRouteOptions(
      context,
      destination,
    );

    if (shouldSearch == true && mounted) {
      _busRouteHandler.findBusRouteTo(destination.location);
    }
  }

  void _showCategoryDialog() {
    MapDialogs.showCategoryDialog(context, (category) {
      setState(() => _state.selectedCategory = category);
      _poiHandler.searchNearbyPOIs();
    });
  }

  Future<void> _showBusLines() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BusLinesScreen()),
    );

    if (result != null && result is BusRoute) {
      _busRouteHandler.showBusRoute(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Mapa
          _buildMap(),

          // Barra de búsqueda y resultados
          _buildSearchSection(),

          // Banner de modo de selección
          if (_state.isSelectingDestination) _buildSelectionBanner(),

          // Botones flotantes
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _state.mapController,
      options: MapOptions(
        initialCenter: _state.currentLocation,
        initialZoom: 13.0,
        minZoom: 11.0,
        maxZoom: 18.0,
        cameraConstraint: CameraConstraint.contain(
          bounds: LatLngBounds(
            const LatLng(-18.0500, -63.3500),
            const LatLng(-17.5000, -62.9000),
          ),
        ),
        onTap: (_, point) {
          _searchHandler.clearSearchResults();
          if (_state.isSelectingDestination) {
            _destinationSelector.selectDestinationOnMap(point);
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.bus',
        ),
        PolylineLayer(polylines: _state.polylines),
        MarkerLayer(markers: _state.markers),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Column(
        children: [
          widgets.SearchBar(
            controller: _state.searchController,
            isSearching: _state.isSearching,
            onChanged: (value) {
              if (value.length > 2) {
                _searchHandler.searchPlaces(value);
              } else if (value.isEmpty) {
                _searchHandler.clearSearchResults();
              }
            },
            onClear: () {
              _state.searchController.clear();
              _searchHandler.clearSearchResults();
            },
          ),
          widgets.SearchResults(
            results: _state.searchResults,
            onPlaceSelected: _searchHandler.selectPlace,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionBanner() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      left: 16,
      right: 16,
      child: widgets.SelectionModeBanner(
        onClose: () {
          setState(() {
            _state.isSelectingDestination = false;
          });
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return Positioned(
      right: 16,
      bottom: 100,
      child: widgets.MapActionButtons(
        isSelectingDestination: _state.isSelectingDestination,
        isLoadingLocation: _state.isLoadingLocation,
        onToggleSelection: _destinationSelector.toggleSelectionMode,
        onShowBusLines: _showBusLines,
        onGetLocation: _locationHandler.getCurrentLocation,
        onShowNearby: _showCategoryDialog,
      ),
    );
  }

  @override
  void dispose() {
    _searchHandler.dispose();
    _state.dispose();
    super.dispose();
  }
}
