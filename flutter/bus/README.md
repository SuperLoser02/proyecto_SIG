# Bus Map App - OpenStreetMap

Aplicación de mapas estilo Google Maps usando alternativas gratuitas y open source.

## 🗺️ Tecnologías Utilizadas

### 1. **OpenStreetMap (OSM)** - Mapa Base
- **Librería**: `flutter_map`
- **Función**: Muestra calles, avenidas, edificios, límites
- **Costo**: ✅ 100% Gratis
- **Equivalente Google**: Google Maps básico

### 2. **Nominatim** - Geocoding API
- **Función**: 
  - Buscar lugares por nombre (ej: "Cine Center Santa Cruz")
  - Convertir texto → coordenadas
  - Geocoding reverso (coordenadas → dirección)
- **Límite**: 1 consulta/segundo en servidor público
- **Costo**: ✅ Gratis
- **Equivalente Google**: Google Geocoding + Places Search

### 3. **Overpass API** - POIs Cercanos
- **Función**:
  - Buscar lugares cercanos (farmacias, restaurantes, paradas de bus)
  - Filtrar por categoría usando etiquetas OSM
- **Costo**: ✅ Gratis
- **Equivalente Google**: Google Places Nearby

### 4. **OSRM** - Motor de Ruteo
- **Función**:
  - Calcula rutas por calles reales
  - Devuelve coordenadas, distancia, duración
  - Perfiles: coche, bici, caminando
- **Costo**: ✅ Gratis (open source)
- **Equivalente Google**: Google Directions API

## 📱 Características

✅ **Mapa interactivo** con OpenStreetMap  
✅ **Búsqueda de lugares** por nombre  
✅ **Ubicación actual** del usuario  
✅ **POIs cercanos** por categoría:
   - Restaurantes
   - Farmacias
   - Paradas de bus
   - Cajeros automáticos
   - Hospitales
   - Supermercados
✅ **Cálculo de rutas** con distancia y duración  
✅ **Marcadores** en el mapa  
✅ **Rutas visualizadas** con polylines

## 🚀 Instalación

```bash
# 1. Instalar dependencias
flutter pub get

# 2. Ejecutar la aplicación
flutter run
```

## 📦 Dependencias

```yaml
dependencies:
  flutter_map: ^7.0.2      # Mapa OSM
  latlong2: ^0.9.1         # Coordenadas
  http: ^1.2.2             # Peticiones HTTP
  geolocator: ^13.0.2      # Ubicación GPS
  permission_handler: ^11.3.1  # Permisos
```

## 🏗️ Estructura del Proyecto

```
lib/
├── main.dart
├── screens/
│   └── map_screen.dart         # Pantalla principal con mapa
├── services/
│   ├── nominatim_service.dart  # Geocoding y búsqueda
│   ├── overpass_service.dart   # POIs cercanos
│   └── osrm_service.dart       # Cálculo de rutas
└── models/
    ├── place.dart              # Modelo de lugar
    ├── poi.dart                # Modelo de POI
    └── route_info.dart         # Modelo de ruta
```

## 🔧 Uso de las APIs

### Buscar un lugar (Nominatim)
```dart
final results = await NominatimService.searchPlace('Pizza Santa Cruz');
```

### Buscar POIs cercanos (Overpass)
```dart
final pois = await OverpassService.searchRestaurants(
  center: LatLng(-17.7833, -63.1821),
  radius: 2000, // metros
);
```

### Calcular ruta (OSRM)
```dart
final route = await OSRMService.getCarRoute([
  LatLng(-17.7833, -63.1821), // Origen
  LatLng(-17.7933, -63.1721), // Destino
]);
```

## 📝 Permisos

### Android
Ya configurado en `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

### iOS
Agregar en `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Necesitamos tu ubicación para mostrarte el mapa</string>
```

## 💡 Ventajas vs Google Maps

| Característica | OpenStreetMap | Google Maps |
|---------------|---------------|-------------|
| **Costo** | ✅ 100% Gratis | ❌ Requiere pago después de límites |
| **Open Source** | ✅ Sí | ❌ No |
| **Sin API Key** | ✅ No requiere | ❌ Requiere API Key |
| **Personalización** | ✅ Total libertad | ⚠️ Limitada |
| **Límites de uso** | ⚠️ 1 req/seg (Nominatim) | ⚠️ Cuotas mensuales |

## ⚠️ Consideraciones

1. **Nominatim**: Límite de 1 consulta/segundo. Para uso intensivo, considera hosting propio
2. **Tiles OSM**: Para producción, considera usar un servidor de tiles propio o servicios como Mapbox
3. **OSRM**: Usa el servidor público demo. Para producción, considera servidor propio

## 🔗 Referencias

- [OpenStreetMap](https://www.openstreetmap.org/)
- [Nominatim API](https://nominatim.org/)
- [Overpass API](https://overpass-api.de/)
- [OSRM](http://project-osrm.org/)
- [flutter_map](https://pub.dev/packages/flutter_map)
