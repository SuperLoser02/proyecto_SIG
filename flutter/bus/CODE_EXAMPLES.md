# Ejemplos de Código - Personalización

## 📍 Ejemplo 1: Usar Ubicación Específica

```dart
// En map_screen.dart, reemplaza la ubicación por defecto

// Santa Cruz, Bolivia
LatLng _currentLocation = const LatLng(-17.7833, -63.1821);

// La Paz, Bolivia
LatLng _currentLocation = const LatLng(-16.5000, -68.1500);

// Cochabamba, Bolivia
LatLng _currentLocation = const LatLng(-17.3935, -66.1570);

// Buenos Aires, Argentina
LatLng _currentLocation = const LatLng(-34.6037, -58.3816);

// Madrid, España
LatLng _currentLocation = const LatLng(40.4168, -3.7038);
```

---

## 🔍 Ejemplo 2: Búsqueda Personalizada con Límites

```dart
// En nominatim_service.dart

/// Buscar lugares en una ciudad específica
static Future<List<Place>> searchInCity(String query, String city) async {
  final uri = Uri.parse('$_baseUrl/search').replace(
    queryParameters: {
      'q': '$query, $city',
      'format': 'json',
      'addressdetails': '1',
      'limit': '5',
      'countrycodes': 'bo', // Limitar a Bolivia
    },
  );
  
  final response = await http.get(uri, headers: _headers);
  // ... resto del código
}

// Uso:
final results = await NominatimService.searchInCity('Pizza', 'Santa Cruz');
```

---

## 🎨 Ejemplo 3: Personalizar Marcadores

```dart
// Marcador personalizado con imagen
Marker(
  point: location,
  width: 50,
  height: 50,
  child: Image.asset('assets/markers/restaurant.png'),
)

// Marcador con texto
Marker(
  point: location,
  width: 80,
  height: 80,
  child: Column(
    children: [
      const Icon(Icons.place, color: Colors.red, size: 40),
      Container(
        padding: const EdgeInsets.all(2),
        color: Colors.white,
        child: Text(
          'Pizza',
          style: const TextStyle(fontSize: 10),
        ),
      ),
    ],
  ),
)

// Marcador animado
class AnimatedMarker extends StatefulWidget {
  final LatLng location;
  
  const AnimatedMarker({Key? key, required this.location}) : super(key: key);
  
  @override
  State<AnimatedMarker> createState() => _AnimatedMarkerState();
}

class _AnimatedMarkerState extends State<AnimatedMarker> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_controller.value * 0.2),
          child: const Icon(Icons.place, color: Colors.red, size: 40),
        );
      },
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

---

## 🗺️ Ejemplo 4: Estilos de Mapa Alternativos

```dart
// Mapa en blanco y negro
TileLayer(
  urlTemplate: 'https://tiles.wmflabs.org/bw-mapnik/{z}/{x}/{y}.png',
  userAgentPackageName: 'com.example.bus',
),

// Mapa topográfico
TileLayer(
  urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
  subdomains: const ['a', 'b', 'c'],
  userAgentPackageName: 'com.example.bus',
),

// Mapa de transporte
TileLayer(
  urlTemplate: 'https://tile.thunderforest.com/transport/{z}/{x}/{y}.png?apikey=YOUR_API_KEY',
  userAgentPackageName: 'com.example.bus',
),

// Mapa oscuro (requiere Mapbox)
TileLayer(
  urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/dark-v10/tiles/{z}/{x}/{y}?access_token=YOUR_TOKEN',
  userAgentPackageName: 'com.example.bus',
),
```

---

## 🛣️ Ejemplo 5: Rutas con Múltiples Puntos (Waypoints)

```dart
// Calcular ruta con paradas intermedias
Future<RouteInfo?> calculateMultiStopRoute() async {
  final waypoints = [
    LatLng(-17.7833, -63.1821), // Inicio
    LatLng(-17.7900, -63.1700), // Parada 1
    LatLng(-17.7950, -63.1650), // Parada 2
    LatLng(-17.8000, -63.1600), // Destino
  ];
  
  final route = await OSRMService.getRoute(
    waypoints: waypoints,
    profile: 'car',
  );
  
  return route;
}

// Mostrar números en cada parada
List<Marker> createWaypointMarkers(List<LatLng> waypoints) {
  return waypoints.asMap().entries.map((entry) {
    final index = entry.key;
    final point = entry.value;
    
    return Marker(
      point: point,
      width: 40,
      height: 40,
      child: Container(
        decoration: BoxDecoration(
          color: index == 0 
              ? Colors.green 
              : index == waypoints.length - 1 
                  ? Colors.red 
                  : Colors.blue,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }).toList();
}
```

---

## 📊 Ejemplo 6: Mostrar Información de Tráfico (Simulado)

```dart
// Polyline con colores según "tráfico"
class TrafficPolyline extends StatelessWidget {
  final List<LatLng> points;
  
  const TrafficPolyline({Key? key, required this.points}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return PolylineLayer(
      polylines: [
        // Línea base
        Polyline(
          points: points,
          color: Colors.grey,
          strokeWidth: 8,
        ),
        // Segmento con tráfico fluido (verde)
        Polyline(
          points: points.sublist(0, points.length ~/ 3),
          color: Colors.green,
          strokeWidth: 6,
        ),
        // Segmento con tráfico moderado (amarillo)
        Polyline(
          points: points.sublist(points.length ~/ 3, 2 * points.length ~/ 3),
          color: Colors.orange,
          strokeWidth: 6,
        ),
        // Segmento con tráfico pesado (rojo)
        Polyline(
          points: points.sublist(2 * points.length ~/ 3),
          color: Colors.red,
          strokeWidth: 6,
        ),
      ],
    );
  }
}
```

---

## 🔔 Ejemplo 7: Notificaciones de Llegada

```dart
import 'package:geolocator/geolocator.dart';

class ArrivalNotifier {
  static const double _arrivalThreshold = 50.0; // metros
  
  /// Monitorear si el usuario está cerca del destino
  static Stream<double> monitorDistance(LatLng destination) {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).map((position) {
      final currentLocation = LatLng(position.latitude, position.longitude);
      return Geolocator.distanceBetween(
        currentLocation.latitude,
        currentLocation.longitude,
        destination.latitude,
        destination.longitude,
      );
    });
  }
  
  /// Verificar si llegó al destino
  static void checkArrival(LatLng destination, Function onArrival) {
    monitorDistance(destination).listen((distance) {
      if (distance <= _arrivalThreshold) {
        onArrival();
      }
    });
  }
}

// Uso en map_screen.dart
void _startNavigating(LatLng destination) {
  ArrivalNotifier.checkArrival(destination, () {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Has llegado a tu destino!'),
        backgroundColor: Colors.green,
      ),
    );
  });
}
```

---

## 💾 Ejemplo 8: Guardar Lugares Favoritos

```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FavoritesService {
  static const String _key = 'favorite_places';
  
  /// Guardar lugar favorito
  static Future<void> addFavorite(Place place) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    
    favorites.add({
      'name': place.displayName,
      'lat': place.location.latitude,
      'lng': place.location.longitude,
    });
    
    await prefs.setString(_key, json.encode(favorites));
  }
  
  /// Obtener lugares favoritos
  static Future<List<Map<String, dynamic>>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);
    
    if (data == null) return [];
    
    return List<Map<String, dynamic>>.from(json.decode(data));
  }
  
  /// Eliminar favorito
  static Future<void> removeFavorite(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    
    favorites.removeWhere((f) => f['name'] == name);
    
    await prefs.setString(_key, json.encode(favorites));
  }
}

// Widget para mostrar favoritos
class FavoritesListWidget extends StatefulWidget {
  final Function(LatLng) onPlaceSelected;
  
  const FavoritesListWidget({Key? key, required this.onPlaceSelected}) 
      : super(key: key);
  
  @override
  State<FavoritesListWidget> createState() => _FavoritesListWidgetState();
}

class _FavoritesListWidgetState extends State<FavoritesListWidget> {
  List<Map<String, dynamic>> _favorites = [];
  
  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }
  
  Future<void> _loadFavorites() async {
    final favorites = await FavoritesService.getFavorites();
    setState(() => _favorites = favorites);
  }
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final fav = _favorites[index];
        return ListTile(
          leading: const Icon(Icons.star, color: Colors.amber),
          title: Text(fav['name']),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              await FavoritesService.removeFavorite(fav['name']);
              _loadFavorites();
            },
          ),
          onTap: () {
            final location = LatLng(fav['lat'], fav['lng']);
            widget.onPlaceSelected(location);
          },
        );
      },
    );
  }
}
```

---

## 🎯 Ejemplo 9: Búsqueda de POIs con Filtros

```dart
/// Buscar POIs con múltiples filtros
class AdvancedPOISearch {
  static Future<List<POI>> searchWithFilters({
    required LatLng center,
    required List<String> categories,
    double radius = 1000,
    String? name,
    bool openNow = false,
  }) async {
    final allPOIs = <POI>[];
    
    // Buscar en cada categoría
    for (final category in categories) {
      final results = await OverpassService.searchNearby(
        center: center,
        category: category,
        radius: radius,
      );
      allPOIs.addAll(results);
    }
    
    // Filtrar por nombre si se especifica
    if (name != null && name.isNotEmpty) {
      return allPOIs.where((poi) {
        return poi.name.toLowerCase().contains(name.toLowerCase());
      }).toList();
    }
    
    return allPOIs;
  }
}

// Uso:
final results = await AdvancedPOISearch.searchWithFilters(
  center: _currentLocation,
  categories: ['amenity=restaurant', 'amenity=cafe'],
  radius: 2000,
  name: 'pizza',
);
```

---

## 🌐 Ejemplo 10: Caché de Búsquedas

```dart
class SearchCache {
  static final Map<String, List<Place>> _cache = {};
  static const Duration _cacheExpiration = Duration(hours: 1);
  static final Map<String, DateTime> _timestamps = {};
  
  static Future<List<Place>> searchWithCache(String query) async {
    // Verificar si existe en caché y no ha expirado
    if (_cache.containsKey(query) && _timestamps.containsKey(query)) {
      final timestamp = _timestamps[query]!;
      if (DateTime.now().difference(timestamp) < _cacheExpiration) {
        print('Usando caché para: $query');
        return _cache[query]!;
      }
    }
    
    // Buscar en API
    print('Buscando en API: $query');
    final results = await NominatimService.searchPlace(query);
    
    // Guardar en caché
    _cache[query] = results;
    _timestamps[query] = DateTime.now();
    
    return results;
  }
  
  static void clearCache() {
    _cache.clear();
    _timestamps.clear();
  }
}
```

---

## 🚀 Consejos de Performance

### 1. Limitar marcadores visibles
```dart
// Solo mostrar los 50 POIs más cercanos
_nearbyPOIs.sort((a, b) {
  final distA = Geolocator.distanceBetween(
    _currentLocation.latitude,
    _currentLocation.longitude,
    a.location.latitude,
    a.location.longitude,
  );
  final distB = Geolocator.distanceBetween(
    _currentLocation.latitude,
    _currentLocation.longitude,
    b.location.latitude,
    b.location.longitude,
  );
  return distA.compareTo(distB);
});

_markers = _nearbyPOIs.take(50).map((poi) => /* ... */).toList();
```

### 2. Debounce en búsquedas
```dart
Timer? _debounce;

void _onSearchChanged(String query) {
  if (_debounce?.isActive ?? false) _debounce!.cancel();
  
  _debounce = Timer(const Duration(milliseconds: 500), () {
    _searchPlaces(query);
  });
}
```

### 3. Cargar marcadores progresivamente
```dart
Future<void> _loadPOIsProgressive() async {
  setState(() => _isLoading = true);
  
  final chunks = _nearbyPOIs.slices(10); // 10 marcadores a la vez
  
  for (final chunk in chunks) {
    setState(() {
      _markers.addAll(chunk.map((poi) => /* crear marcador */));
    });
    await Future.delayed(const Duration(milliseconds: 100));
  }
  
  setState(() => _isLoading = false);
}
```
