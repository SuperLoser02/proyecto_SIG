import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/place.dart';
import '../models/poi.dart';
import '../models/route_info.dart';
import '../models/bus_line.dart';
import '../models/bus_route_recommendation.dart';
import '../services/nominatim_service.dart';
import '../services/overpass_service.dart';
import '../services/osrm_service.dart';
import '../services/bus_line_service.dart';
import '../services/location_service.dart';
import '../utils/map_markers.dart';
import '../utils/route_visualizer.dart';
import '../utils/map_dialogs.dart';
import 'bus_lines_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng _currentLocation = const LatLng(
    -17.7833,
    -63.1821,
  ); // Santa Cruz, Bolivia
  List<Place> _searchResults = [];
  RouteInfo? _currentRoute;

  List<Marker> _markers = [];
  List<Polyline> _polylines = [];

  bool _isSearching = false;
  bool _isLoadingLocation = false;
  String _selectedCategory = 'amenity=restaurant';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // Actualizar ubicación sin mover el mapa (para búsqueda de rutas)
  Future<void> _updateCurrentLocation() async {
    final location = await LocationService.getCurrentLocation();
    if (location != null && mounted) {
      setState(() {
        _currentLocation = location;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    final location = await LocationService.getCurrentLocation();

    if (location != null && mounted) {
      setState(() {
        _currentLocation = location;
        _isLoadingLocation = false;
        _markers = [MapMarkers.userLocationMarker(_currentLocation)];
      });
      _mapController.move(_currentLocation, 16.0);
    } else if (mounted) {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    final results = await NominatimService.searchPlace(query);

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  void _selectPlace(Place place) {
    setState(() {
      _searchResults = [];
      _searchController.clear();
      _markers = [
        MapMarkers.userLocationMarker(_currentLocation),
        MapMarkers.destinationMarkerSimple(place.location),
      ];
    });

    _mapController.move(place.location, 16.0);

    Future.delayed(const Duration(milliseconds: 300), () {
      _showBusRouteOptions(place);
    });
  }

  Future<void> _showBusRouteOptions(Place destination) async {
    final shouldSearch = await MapDialogs.showBusRouteOptions(
      context,
      destination,
    );

    if (shouldSearch == true && mounted) {
      _findBusRouteTo(destination.location);
    }
  }

  Future<void> _findBusRouteTo(LatLng destination) async {
    MapDialogs.showLoadingDialog(context);

    try {
      await _updateCurrentLocation();
      await BusLineService.instance.loadData();
      final recommendations = BusLineService.instance.findBestRoutes(
        from: _currentLocation,
        to: destination,
        maxResults: 5,
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (recommendations.isEmpty) {
        MapDialogs.showNoRoutesFound(context, _currentLocation, destination);
        return;
      }

      MapDialogs.showBusRouteRecommendations(
        context,
        recommendations: recommendations,
        currentLocation: _currentLocation,
        destination: destination,
        onRouteSelected: (rec) => _showRecommendedRoute(rec, destination),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      MapDialogs.showRouteError(context, e.toString(), _currentLocation);
    }
  }

  void _showRecommendedRoute(
    BusRouteRecommendation recommendation,
    LatLng destination,
  ) {
    setState(() {
      _currentRoute = null;

      // Crear polylines usando RouteVisualizer
      _polylines = RouteVisualizer.recommendationPolylines(
        userLocation: _currentLocation,
        destination: destination,
        recommendation: recommendation,
      );

      // Crear marcadores
      _markers = [
        MapMarkers.userLocationWithLabel(_currentLocation),
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

      // Centrar mapa mostrando todo el recorrido
      final allPoints = [
        _currentLocation,
        ...recommendation.routeSegment,
        if (recommendation.isTransfer &&
            recommendation.transferRouteSegment != null)
          ...recommendation.transferRouteSegment!,
        destination,
      ];
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(allPoints),
          padding: const EdgeInsets.all(50),
        ),
      );
    });

    MapDialogs.showRouteSelectedSnackBar(context, recommendation);
  }

  Future<void> _searchNearbyPOIs() async {
    final results = await OverpassService.searchNearby(
      center: _currentLocation,
      category: _selectedCategory,
      radius: 3000,
    );

    setState(() {
      _markers = [
        MapMarkers.userLocationMarkerCompact(_currentLocation),
        ...results.map(
          (poi) => MapMarkers.poiMarker(poi, onTap: () => _showPOIDetails(poi)),
        ),
      ];
    });
  }

  void _showPOIDetails(POI poi) {
    MapDialogs.showPOIDetails(
      context,
      poi,
      () => _calculateRoute(poi.location),
    );
  }

  Future<void> _calculateRoute(LatLng destination) async {
    final route = await OSRMService.getCarRoute([
      _currentLocation,
      destination,
    ]);

    if (route != null && mounted) {
      setState(() {
        _currentRoute = route;
        _polylines = [RouteVisualizer.calculatedRoutePolyline(route.geometry)];
        _markers = [
          MapMarkers.originMarker(_currentLocation),
          MapMarkers.destinationMarkerSimple(destination),
        ];
      });

      _showRouteInfo();
    }
  }

  void _showRouteInfo() {
    if (_currentRoute == null) return;
    MapDialogs.showCalculatedRouteInfo(
      context,
      _currentRoute!.distanceFormatted,
      _currentRoute!.durationFormatted,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Mapa
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 13.0,
              minZoom:
                  11.0, // Limitar zoom mínimo para mantener vista en Santa Cruz
              maxZoom: 18.0, // Zoom máximo para ver calles
              // Limitar el área visible a Santa Cruz, Bolivia
              cameraConstraint: CameraConstraint.contain(
                bounds: LatLngBounds(
                  const LatLng(-18.0500, -63.3500), // Suroeste de Santa Cruz
                  const LatLng(-17.5000, -62.9000), // Noreste de Santa Cruz
                ),
              ),
              onTap: (_, point) {
                setState(() {
                  _searchResults = [];
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.bus',
              ),
              PolylineLayer(polylines: _polylines),
              MarkerLayer(markers: _markers),
            ],
          ),

          // Barra de búsqueda
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Card(
                  elevation: 4,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar lugar en Santa Cruz...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchResults = [];
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      if (value.length > 2) {
                        _searchPlaces(value);
                      } else if (value.isEmpty) {
                        setState(() => _searchResults = []);
                      }
                    },
                  ),
                ),

                // Resultados de búsqueda
                if (_searchResults.isNotEmpty)
                  Card(
                    elevation: 4,
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final place = _searchResults[index];
                          return ListTile(
                            leading: const Icon(Icons.place, color: Colors.red),
                            title: Text(
                              place.shortName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              place.displayName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () => _selectPlace(place),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Botones de acción
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'bus_lines',
                  backgroundColor: Colors.orange,
                  onPressed: _showBusLines,
                  child: const Icon(Icons.directions_bus),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'location',
                  onPressed: _getCurrentLocation,
                  child: _isLoadingLocation
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Icon(Icons.my_location),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'nearby',
                  onPressed: () => _showCategoryDialog(),
                  child: const Icon(Icons.near_me),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryDialog() {
    MapDialogs.showCategoryDialog(context, (category) {
      setState(() => _selectedCategory = category);
      _searchNearbyPOIs();
    });
  }

  Future<void> _showBusLines() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BusLinesScreen()),
    );

    if (result != null && result is BusRoute) {
      _showBusRoute(result);
    }
  }

  void _showBusRoute(BusRoute busRoute) {
    setState(() {
      _currentRoute = null;
      _polylines = [RouteVisualizer.simpleBusRoutePolyline(busRoute)];

      if (busRoute.points.isNotEmpty) {
        _markers = MapMarkers.busRouteMarkers(busRoute);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(busRoute.coordinates),
            padding: const EdgeInsets.all(50),
          ),
        );
      }
    });

    MapDialogs.showBusRouteSnackBar(context, busRoute);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
