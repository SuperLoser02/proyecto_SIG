import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/place.dart';
import '../models/poi.dart';
import '../models/route_info.dart';
import '../models/bus_line.dart';
import '../services/nominatim_service.dart';
import '../services/overpass_service.dart';
import '../services/osrm_service.dart';
import '../services/bus_line_service.dart';
import '../utils/poi_categories.dart';
import 'bus_lines_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  
  LatLng _currentLocation = const LatLng(-17.7833, -63.1821); // Santa Cruz, Bolivia
  List<Place> _searchResults = [];
  List<POI> _nearbyPOIs = [];
  RouteInfo? _currentRoute;
  BusRoute? _selectedBusRoute;
  
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
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      // Si falla, usar la ubicación actual que ya tenemos
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
        
        // Agregar marcador en la ubicación actual
        _markers = [
          Marker(
            point: _currentLocation,
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Círculo exterior pulsante
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                ),
                // Círculo medio
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                ),
                // Punto central (tu ubicación)
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ];
      });
      
      _mapController.move(_currentLocation, 16.0);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
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
      
      // Mantener marcador de ubicación actual y agregar marcador de destino
      _markers = [
        // Marcador de ubicación actual
        Marker(
          point: _currentLocation,
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Marcador de destino
        Marker(
          point: place.location,
          width: 50,
          height: 50,
          child: const Icon(
            Icons.place,
            color: Colors.red,
            size: 50,
            shadows: [
              Shadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ];
    });
    
    _mapController.move(place.location, 16.0);
    
    // Ofrecer buscar ruta de micro a este lugar inmediatamente
    Future.delayed(const Duration(milliseconds: 300), () {
      _showBusRouteOptions(place);
    });
  }

  Future<void> _showBusRouteOptions(Place destination) async {
    final shouldSearch = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.directions_bus, size: 48, color: Colors.orange),
        title: const Text('¿Buscar línea de micro?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Deseas buscar qué línea de micro te lleva a:',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              destination.shortName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              destination.displayName,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.search),
            label: const Text('Buscar Rutas'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (shouldSearch == true && mounted) {
      _findBusRouteTo(destination.location);
    }
  }

  Future<void> _findBusRouteTo(LatLng destination) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Obteniendo tu ubicación actual...'),
                SizedBox(height: 8),
                Text('Buscando mejor ruta de micro...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Actualizar ubicación actual antes de buscar rutas
      await _updateCurrentLocation();
      
      await BusLineService.instance.loadData();
      final recommendations = BusLineService.instance.findBestRoutes(
        from: _currentLocation,
        to: destination,
        maxResults: 5,
      );

      if (!mounted) return;
      Navigator.pop(context); // Cerrar diálogo de carga

      if (recommendations.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No se encontraron rutas de micro',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Desde: ${_currentLocation.latitude.toStringAsFixed(4)}, ${_currentLocation.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Hacia: ${destination.latitude.toStringAsFixed(4)}, ${destination.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Intenta con un destino más cercano o dentro de Santa Cruz',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }

      _showBusRouteRecommendations(recommendations, destination);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Error al buscar rutas',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('$e'),
              const SizedBox(height: 4),
              Text(
                'Tu ubicación: ${_currentLocation.latitude.toStringAsFixed(4)}, ${_currentLocation.longitude.toStringAsFixed(4)}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _showBusRouteRecommendations(
    List<BusRouteRecommendation> recommendations,
    LatLng destination,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_bus, color: Colors.blue, size: 28),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Rutas de Micro Disponibles',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.my_location, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Desde tu ubicación actual (${_currentLocation.latitude.toStringAsFixed(4)}, ${_currentLocation.longitude.toStringAsFixed(4)})',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.place, size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Hacia: ${destination.latitude.toStringAsFixed(4)}, ${destination.longitude.toStringAsFixed(4)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: recommendations.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final rec = recommendations[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          _showRecommendedRoute(rec, destination);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Etiqueta de transbordo si aplica
                              if (rec.isTransfer)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.swap_horiz, size: 16, color: Colors.orange.shade800),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Con Transbordo',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: rec.route.line.color,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      rec.route.line.displayName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (rec.isTransfer && rec.transferRoute != null) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward, size: 16),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: rec.transferRoute!.line.color,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        rec.transferRoute!.line.displayName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                children: [
                                  const Icon(Icons.directions_walk, size: 20, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text('${rec.formattedWalkToStart} a pie'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.directions_bus, size: 20, color: rec.route.line.color),
                                  const SizedBox(width: 8),
                                  Text('${rec.formattedBusDistance} en micro'),
                                ],
                              ),
                              if (rec.isTransfer && rec.transferWalkDistance != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.transfer_within_a_station, size: 20, color: Colors.orange),
                                    const SizedBox(width: 8),
                                    Text('${(rec.transferWalkDistance! < 1000 ? "${rec.transferWalkDistance!.toStringAsFixed(0)} m" : "${(rec.transferWalkDistance! / 1000).toStringAsFixed(2)} km")} transbordo'),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.directions_walk, size: 20, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text('${rec.formattedWalkFromEnd} a pie'),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Distancia total:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      rec.formattedTotalDistance,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: rec.route.line.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecommendedRoute(BusRouteRecommendation recommendation, LatLng destination) {
    setState(() {
      _selectedBusRoute = recommendation.route;
      _currentRoute = null;

      // Crear polylines según si hay transbordo o no
      if (recommendation.isTransfer && recommendation.transferRoute != null) {
        // Ruta con transbordo: 5 segmentos
        _polylines = [
          // 1. Caminata al punto de inicio del primer micro
          Polyline(
            points: [_currentLocation, recommendation.startPoint.location],
            color: Colors.grey,
            strokeWidth: 3.0,
            borderStrokeWidth: 1.0,
            borderColor: Colors.white,
          ),
          // 2. Ruta del primer micro
          Polyline(
            points: recommendation.routeSegment,
            color: recommendation.route.line.color,
            strokeWidth: 5.0,
          ),
          // 3. Caminata al transbordo
          Polyline(
            points: [
              recommendation.endPoint.location,
              recommendation.transferRoute!.points[recommendation.transferStartIndex!].location,
            ],
            color: Colors.orange,
            strokeWidth: 3.0,
            borderStrokeWidth: 1.0,
            borderColor: Colors.white,
          ),
          // 4. Ruta del segundo micro
          Polyline(
            points: recommendation.transferRouteSegment!,
            color: recommendation.transferRoute!.line.color,
            strokeWidth: 5.0,
          ),
          // 5. Caminata al destino final
          Polyline(
            points: [
              recommendation.transferRoute!.points[recommendation.transferEndIndex!].location,
              destination,
            ],
            color: Colors.grey,
            strokeWidth: 3.0,
            borderStrokeWidth: 1.0,
            borderColor: Colors.white,
          ),
        ];
      } else {
        // Ruta directa: 3 segmentos
        _polylines = [
          // Caminata al punto de inicio del micro
          Polyline(
            points: [_currentLocation, recommendation.startPoint.location],
            color: Colors.grey,
            strokeWidth: 3.0,
            borderStrokeWidth: 1.0,
            borderColor: Colors.white,
          ),
          // Ruta del micro
          Polyline(
            points: recommendation.routeSegment,
            color: recommendation.route.line.color,
            strokeWidth: 5.0,
          ),
          // Caminata desde el punto final del micro al destino
          Polyline(
            points: [recommendation.endPoint.location, destination],
            color: Colors.grey,
            strokeWidth: 3.0,
            borderStrokeWidth: 1.0,
            borderColor: Colors.white,
          ),
        ];
      }

      // Marcadores
      _markers = [
        // Tu ubicación
        Marker(
          point: _currentLocation,
          width: 60,
          height: 60,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
              const Text('Tú', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        // Punto donde tomas el primer micro
        Marker(
          point: recommendation.startPoint.location,
          width: 80,
          height: 80,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: recommendation.route.line.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  recommendation.route.line.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Icon(
                Icons.bus_alert,
                color: recommendation.route.line.color,
                size: 30,
              ),
              const Text('Subir', style: TextStyle(fontSize: 10)),
            ],
          ),
        ),
        // Marcadores adicionales para transbordo
        if (recommendation.isTransfer && recommendation.transferRoute != null) ...[
          // Punto de transbordo
          Marker(
            point: recommendation.endPoint.location,
            width: 80,
            height: 80,
            child: Column(
              children: [
                Icon(
                  Icons.transfer_within_a_station,
                  color: Colors.orange,
                  size: 30,
                ),
                const Text('Transbordo', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          // Punto donde tomas el segundo micro
          Marker(
            point: recommendation.transferRoute!.points[recommendation.transferStartIndex!].location,
            width: 80,
            height: 80,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: recommendation.transferRoute!.line.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    recommendation.transferRoute!.line.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Icon(
                  Icons.bus_alert,
                  color: recommendation.transferRoute!.line.color,
                  size: 30,
                ),
                const Text('Subir', style: TextStyle(fontSize: 10)),
              ],
            ),
          ),
          // Punto donde bajas del segundo micro
          Marker(
            point: recommendation.transferRoute!.points[recommendation.transferEndIndex!].location,
            width: 60,
            height: 60,
            child: Column(
              children: [
                Icon(
                  Icons.stop_circle,
                  color: recommendation.transferRoute!.line.color,
                  size: 30,
                ),
                const Text('Bajar', style: TextStyle(fontSize: 10)),
              ],
            ),
          ),
        ] else ...[
          // Punto donde bajas del micro (sin transbordo)
          Marker(
            point: recommendation.endPoint.location,
            width: 60,
            height: 60,
            child: Column(
              children: [
                Icon(
                  Icons.stop_circle,
                  color: recommendation.route.line.color,
                  size: 30,
                ),
                const Text('Bajar', style: TextStyle(fontSize: 10)),
              ],
            ),
          ),
        ],
        // Destino final
        Marker(
          point: destination,
          width: 60,
          height: 60,
          child: const Column(
            children: [
              Icon(Icons.place, color: Colors.red, size: 40),
              Text('Destino', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ];

      // Centrar mapa mostrando todo el recorrido
      final allPoints = [
        _currentLocation,
        ...recommendation.routeSegment,
        if (recommendation.isTransfer && recommendation.transferRouteSegment != null)
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

    // Mostrar resumen
    final summaryText = recommendation.isTransfer && recommendation.transferRoute != null
        ? 'Camina ${recommendation.formattedWalkToStart} → ${recommendation.route.line.displayName} → Transbordo → ${recommendation.transferRoute!.line.displayName} → Camina ${recommendation.formattedWalkFromEnd}'
        : 'Camina ${recommendation.formattedWalkToStart} → ${recommendation.route.line.displayName} → Camina ${recommendation.formattedWalkFromEnd}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              recommendation.routeDescription,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(summaryText),
          ],
        ),
        duration: const Duration(seconds: 5),
        backgroundColor: recommendation.route.line.color,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  Future<void> _searchNearbyPOIs() async {
    final results = await OverpassService.searchNearby(
      center: _currentLocation,
      category: _selectedCategory,
      radius: 3000,  // 3km de radio en Santa Cruz
    );

    setState(() {
      _nearbyPOIs = results;
      
      // Agregar marcadores de POIs + marcador de ubicación actual
      _markers = [
        // Tu ubicación actual
        Marker(
          point: _currentLocation,
          width: 50,
          height: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        // POIs encontrados
        ...results.map((poi) {
          return Marker(
            point: poi.location,
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => _showPOIDetails(poi),
              child: const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 40,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          );
        }),
      ];
    });
  }

  void _showPOIDetails(POI poi) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              poi.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Categoría: ${poi.category}'),
            if (poi.address.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Dirección: ${poi.address}'),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _calculateRoute(poi.location);
                    },
                    icon: const Icon(Icons.directions),
                    label: const Text('Cómo llegar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _calculateRoute(LatLng destination) async {
    final route = await OSRMService.getCarRoute([_currentLocation, destination]);
    
    if (route != null) {
      setState(() {
        _currentRoute = route;
        _polylines = [
          Polyline(
            points: route.geometry,
            color: Colors.blue,
            strokeWidth: 5,
            borderColor: Colors.white,
            borderStrokeWidth: 2,
          ),
        ];
        
        _markers = [
          // Marcador de origen (tu ubicación)
          Marker(
            point: _currentLocation,
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                ),
                const Icon(
                  Icons.my_location,
                  color: Colors.green,
                  size: 30,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 4,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Marcador de destino
          Marker(
            point: destination,
            width: 50,
            height: 50,
            child: const Icon(
              Icons.place,
              color: Colors.red,
              size: 50,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ];
      });

      _showRouteInfo();
    }
  }

  void _showRouteInfo() {
    if (_currentRoute == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información de ruta',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.straighten),
                const SizedBox(width: 8),
                Text('Distancia: ${_currentRoute!.distanceFormatted}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time),
                const SizedBox(width: 8),
                Text('Duración: ${_currentRoute!.durationFormatted}'),
              ],
            ),
          ],
        ),
      ),
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
              minZoom: 11.0,  // Limitar zoom mínimo para mantener vista en Santa Cruz
              maxZoom: 18.0,  // Zoom máximo para ver calles
              // Limitar el área visible a Santa Cruz, Bolivia
              cameraConstraint: CameraConstraint.contain(
                bounds: LatLngBounds(
                  const LatLng(-18.0500, -63.3500),  // Suroeste de Santa Cruz
                  const LatLng(-17.5000, -62.9000),  // Noreste de Santa Cruz
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
                                child: CircularProgressIndicator(strokeWidth: 2),
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
                              style: const TextStyle(fontWeight: FontWeight.bold),
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
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buscar lugares cercanos'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: POICategory.categories.length,
            itemBuilder: (context, index) {
              final category = POICategory.categories[index];
              return ListTile(
                leading: Icon(category.icon, color: category.color),
                title: Text(category.name),
                onTap: () {
                  setState(() => _selectedCategory = category.query);
                  Navigator.pop(context);
                  _searchNearbyPOIs();
                },
              );
            },
          ),
        ),
      ),
    );
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
      _selectedBusRoute = busRoute;
      _currentRoute = null; // Limpiar ruta calculada si existe
      
      // Crear polyline de la ruta del micro
      _polylines = [
        Polyline(
          points: busRoute.coordinates,
          color: busRoute.line.color,
          strokeWidth: 4.0,
        ),
      ];

      // Agregar marcadores de inicio y fin
      if (busRoute.points.isNotEmpty) {
        final firstPoint = busRoute.points.first;
        final lastPoint = busRoute.points.last;

        _markers = [
          // Marcador de inicio
          Marker(
            point: firstPoint.location,
            width: 60,
            height: 60,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: busRoute.line.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    busRoute.line.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Icon(
                  Icons.play_arrow,
                  color: busRoute.line.color,
                  size: 30,
                ),
              ],
            ),
          ),
          // Marcador de fin
          Marker(
            point: lastPoint.location,
            width: 50,
            height: 50,
            child: Icon(
              Icons.stop_circle,
              color: busRoute.line.color,
              size: 50,
            ),
          ),
        ];

        // Centrar mapa en la ruta
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(busRoute.coordinates),
            padding: const EdgeInsets.all(50),
          ),
        );
      }
    });

    // Mostrar información de la ruta
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              busRoute.description,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('${busRoute.formattedDistance} • ${busRoute.formattedTime}'),
          ],
        ),
        duration: const Duration(seconds: 4),
        backgroundColor: busRoute.line.color,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
