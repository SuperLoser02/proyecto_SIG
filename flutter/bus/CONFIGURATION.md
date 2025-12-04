# Configuración de la Aplicación

## 🔧 Variables de Configuración

### Ubicación Inicial
```dart
// lib/screens/map_screen.dart - línea ~22
LatLng _currentLocation = const LatLng(-17.7833, -63.1821); // Santa Cruz, Bolivia
```

**Otras ciudades de Bolivia:**
- La Paz: `LatLng(-16.5000, -68.1500)`
- Cochabamba: `LatLng(-17.3935, -66.1570)`
- Sucre: `LatLng(-19.0333, -65.2627)`
- Tarija: `LatLng(-21.5355, -64.7296)`

---

## 🗺️ Configuración del Mapa

### Zoom Inicial
```dart
// lib/screens/map_screen.dart
initialZoom: 15.0  // Rango: 1 (mundo) a 20 (calle)
```

### Límites de Zoom
```dart
MapOptions(
  initialCenter: _currentLocation,
  initialZoom: 15.0,
  minZoom: 5.0,   // Mínimo
  maxZoom: 18.0,  // Máximo
)
```

---

## 📡 APIs y Límites

### OpenStreetMap Tiles
- **URL**: `https://tile.openstreetmap.org/{z}/{x}/{y}.png`
- **Límite**: Uso moderado (no comercial intensivo)
- **User-Agent**: `com.example.bus` (cambiar en producción)

### Nominatim
- **URL Base**: `https://nominatim.openstreetmap.org`
- **Límite**: 1 consulta/segundo
- **Headers requeridos**: User-Agent personalizado

### Overpass API
- **URL Base**: `https://overpass-api.de/api/interpreter`
- **Timeout**: 25 segundos
- **Límite**: Uso razonable

### OSRM
- **URL Base**: `https://router.project-osrm.org`
- **Perfiles**: car, bike, foot
- **Límite**: Servidor demo público

---

## 🔍 Configuración de Búsqueda

### Radio de búsqueda POIs
```dart
// lib/screens/map_screen.dart - método _searchNearbyPOIs
radius: 2000, // metros (2 km)
```

**Valores recomendados:**
- Ciudad pequeña: 1000-2000m
- Ciudad mediana: 2000-5000m
- Ciudad grande: 5000-10000m

### Límite de resultados de búsqueda
```dart
// lib/services/nominatim_service.dart
'limit': '10',  // Número de resultados
```

---

## 🎨 Personalización Visual

### Colores de Rutas
```dart
// lib/screens/map_screen.dart - método _calculateRoute
Polyline(
  points: route.geometry,
  color: Colors.blue,      // Color de ruta
  strokeWidth: 4,          // Grosor de línea
)
```

### Colores de Marcadores
```dart
// Ubicación actual
Icon(Icons.my_location, color: Colors.green, size: 40)

// Destino
Icon(Icons.place, color: Colors.red, size: 40)

// POIs
Icon(Icons.location_on, color: Colors.blue, size: 30)
```

---

## 📱 Permisos

### Android (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

### iOS (Info.plist)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Necesitamos tu ubicación para mostrarte en el mapa</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>Necesitamos tu ubicación para mostrarte en el mapa</string>
```

---

## 🚀 Configuración para Producción

### 1. Cambiar User-Agent
```dart
// lib/services/nominatim_service.dart
static final Map<String, String> _headers = {
  'User-Agent': 'TuApp/1.0 (contacto@tudominio.com)',
};
```

### 2. Usar servidor de tiles propio
```dart
TileLayer(
  urlTemplate: 'https://tu-servidor.com/tiles/{z}/{x}/{y}.png',
  userAgentPackageName: 'com.tuempresa.tuapp',
)
```

### 3. Implementar Rate Limiting
```dart
class RateLimiter {
  static DateTime? _lastRequest;
  static const Duration _minInterval = Duration(seconds: 1);
  
  static Future<void> throttle() async {
    if (_lastRequest != null) {
      final elapsed = DateTime.now().difference(_lastRequest!);
      if (elapsed < _minInterval) {
        await Future.delayed(_minInterval - elapsed);
      }
    }
    _lastRequest = DateTime.now();
  }
}

// Uso antes de cada llamada a Nominatim:
await RateLimiter.throttle();
final results = await NominatimService.searchPlace(query);
```

### 4. Implementar Caché
```dart
// Agregar a pubspec.yaml:
dependencies:
  hive: ^2.2.3
  hive_flutter: ^1.1.0

// Implementar caché de tiles y búsquedas
```

---

## 🔒 Seguridad

### No exponer claves API en código
```dart
// ❌ MAL
const apiKey = 'mi_clave_secreta';

// ✅ BIEN - usar variables de entorno
const apiKey = String.fromEnvironment('API_KEY');
```

### Ofuscar código en producción
```bash
flutter build apk --obfuscate --split-debug-info=debug-info/
```

---

## 📊 Métricas y Analytics

### Firebase Analytics (opcional)
```yaml
# pubspec.yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_analytics: ^10.8.0
```

### Tracking de eventos
```dart
// Búsqueda de lugares
FirebaseAnalytics.instance.logEvent(
  name: 'search_place',
  parameters: {'query': query},
);

// Cálculo de rutas
FirebaseAnalytics.instance.logEvent(
  name: 'calculate_route',
  parameters: {'mode': profile},
);
```

---

## 🧪 Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/
```

---

## 📦 Build para Producción

### Android
```bash
# APK
flutter build apk --release

# App Bundle (recomendado para Play Store)
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

---

## 🔄 Actualización de Dependencias

```bash
# Ver dependencias desactualizadas
flutter pub outdated

# Actualizar a última versión compatible
flutter pub upgrade

# Actualizar a última versión (incluso breaking changes)
flutter pub upgrade --major-versions
```

---

## 💡 Tips de Performance

1. **Limitar marcadores simultáneos**: Máximo 50-100
2. **Implementar clustering** para muchos POIs
3. **Lazy loading** de tiles del mapa
4. **Debounce** en búsquedas (500ms)
5. **Caché** de búsquedas frecuentes
6. **Comprimir imágenes** de marcadores personalizados

---

## 📞 Soporte

Para preguntas o problemas:
1. Revisa la documentación en `README.md`
2. Consulta ejemplos en `CODE_EXAMPLES.md`
3. Lee la guía de uso en `USAGE_GUIDE.md`

---

## 🔗 Links Útiles

- [OpenStreetMap Wiki](https://wiki.openstreetmap.org/)
- [Nominatim Docs](https://nominatim.org/release-docs/latest/)
- [Overpass API](https://wiki.openstreetmap.org/wiki/Overpass_API)
- [OSRM Docs](http://project-osrm.org/docs/)
- [flutter_map Docs](https://docs.fleaflet.dev/)
- [OSM Tag Info](https://taginfo.openstreetmap.org/)
