# Guía de Uso - Bus Map App

## 🎯 Funcionalidades Principales

### 1. Ver el Mapa
Al abrir la app, verás un mapa interactivo centrado en Santa Cruz, Bolivia (puedes cambiar la ubicación por defecto en `map_screen.dart`).

**Controles del mapa:**
- **Zoom**: Pellizca con dos dedos o usa los botones +/-
- **Mover**: Arrastra el mapa con un dedo
- **Rotar**: Gira con dos dedos (opcional)

---

### 2. 📍 Obtener tu Ubicación Actual

**Pasos:**
1. Presiona el botón flotante con icono de ubicación 📍 (abajo a la derecha)
2. Acepta los permisos de ubicación si es la primera vez
3. El mapa se centrará automáticamente en tu ubicación
4. Verás un marcador verde en tu posición actual

**Nota:** Asegúrate de tener GPS activado en tu dispositivo.

---

### 3. 🔍 Buscar Lugares por Nombre

**Pasos:**
1. Toca la barra de búsqueda en la parte superior
2. Escribe el nombre del lugar (ej: "Plaza 24 de Septiembre")
3. Los resultados aparecerán automáticamente mientras escribes
4. Selecciona el lugar deseado de la lista
5. El mapa se moverá al lugar seleccionado con un marcador rojo 🔴

**Ejemplos de búsqueda:**
- "Cine Center Santa Cruz"
- "Parque Urbano"
- "Supermercado Hipermaxi"
- "Hospital Japonés"

---

### 4. 🏪 Buscar Lugares Cercanos (POIs)

**Pasos:**
1. Presiona el botón flotante con icono de navegación 🧭
2. Selecciona una categoría:
   - 🍽️ Restaurantes
   - 💊 Farmacias
   - 🚌 Paradas de bus
   - 🏧 Cajeros ATM
   - 🏥 Hospitales
   - 🛒 Supermercados
   - ⛽ Gasolineras
   - 🏦 Bancos
   - ☕ Cafeterías
   - 🌳 Parques

3. La app buscará lugares en un radio de 2km de tu ubicación actual
4. Verás marcadores azules 🔵 en el mapa para cada lugar encontrado

**Para ver detalles de un lugar:**
1. Toca cualquier marcador azul
2. Se abrirá una ventana con:
   - Nombre del lugar
   - Categoría
   - Dirección (si está disponible)
3. Presiona "Cómo llegar" para calcular la ruta

---

### 5. 🗺️ Calcular Rutas

**Pasos:**
1. Busca un lugar o toca un POI cercano
2. En la ventana de detalles, presiona "Cómo llegar"
3. La app calculará la ruta en coche desde tu ubicación actual
4. Verás:
   - Una línea azul mostrando la ruta
   - Marcador verde 🟢 en tu ubicación
   - Marcador rojo 🔴 en el destino
   - Ventana con información:
     - ⏱️ Duración estimada
     - 📏 Distancia total

**Tipos de ruta disponibles:**
- 🚗 **Coche** (por defecto)
- 🚴 **Bicicleta** (modificar en código)
- 🚶 **Caminando** (modificar en código)

Para cambiar el tipo de transporte, edita `osrm_service.dart` y usa:
```dart
// Para bicicleta
OSRMService.getBikeRoute([origen, destino]);

// Para caminar
OSRMService.getWalkingRoute([origen, destino]);
```

---

## 🛠️ Personalización

### Cambiar ubicación inicial
Edita `map_screen.dart` línea ~22:
```dart
LatLng _currentLocation = const LatLng(-17.7833, -63.1821); // Santa Cruz
```

Reemplaza con tus coordenadas:
```dart
LatLng _currentLocation = const LatLng(TU_LATITUD, TU_LONGITUD);
```

### Cambiar radio de búsqueda de POIs
Edita `map_screen.dart` línea ~95:
```dart
final results = await OverpassService.searchNearby(
  center: _currentLocation,
  category: _selectedCategory,
  radius: 2000, // Cambia este valor (en metros)
);
```

### Agregar más categorías de POIs
Edita `lib/utils/poi_categories.dart` y agrega nuevas categorías:
```dart
POICategory(
  name: 'Tu Categoría',
  query: 'amenity=tu_query', // Ver etiquetas OSM
  icon: Icons.tu_icono,
  color: Colors.tuColor,
),
```

**Consulta etiquetas OSM:** https://wiki.openstreetmap.org/wiki/Map_Features

---

## ⚠️ Solución de Problemas

### No se muestra el mapa
- Verifica conexión a internet
- Los tiles de OSM requieren internet

### No se obtiene la ubicación
- Activa GPS en tu dispositivo
- Acepta permisos de ubicación
- Verifica que los permisos estén en AndroidManifest.xml e Info.plist

### La búsqueda no funciona
- Verifica conexión a internet
- Nominatim tiene límite de 1 consulta/segundo
- Espera unos segundos entre búsquedas

### No se calculan rutas
- Verifica que ambos puntos estén en calles/caminos
- OSRM puede fallar en zonas sin datos de OSM
- Verifica conexión a internet

### Los POIs no aparecen
- Asegúrate de estar en una zona con datos de OSM
- Aumenta el radio de búsqueda
- Algunas categorías pueden no tener datos en tu zona

---

## 🌐 APIs Usadas (Todas Gratuitas)

### OpenStreetMap
- **Tiles del mapa**: `https://tile.openstreetmap.org`
- Sin límites estrictos, pero usa con moderación

### Nominatim
- **Geocoding**: `https://nominatim.openstreetmap.org`
- **Límite**: 1 consulta/segundo
- **User-Agent**: Requerido (ya configurado)

### Overpass API
- **POIs**: `https://overpass-api.de/api/interpreter`
- **Timeout**: 25 segundos por consulta
- Uso razonable

### OSRM
- **Rutas**: `https://router.project-osrm.org`
- Servidor de demo público
- Para producción, considera servidor propio

---

## 🚀 Para Producción

### 1. Servidor de Tiles Propio
```yaml
# Usa Mapbox, Thunderforest u otro proveedor
TileLayer(
  urlTemplate: 'https://tu-servidor/{z}/{x}/{y}.png',
  userAgentPackageName: 'com.tuapp.nombre',
),
```

### 2. Servidor Nominatim Propio
```dart
static const String _baseUrl = 'https://tu-servidor-nominatim.com';
```

### 3. Servidor OSRM Propio
```dart
static const String _baseUrl = 'https://tu-servidor-osrm.com';
```

### 4. Rate Limiting
Implementa caché y debounce para búsquedas:
```dart
Timer? _debounce;
void _searchPlaces(String query) {
  if (_debounce?.isActive ?? false) _debounce!.cancel();
  _debounce = Timer(const Duration(milliseconds: 500), () {
    // Realizar búsqueda
  });
}
```

---

## 📱 Capturas Recomendadas

1. **Pantalla principal** con mapa de Santa Cruz
2. **Búsqueda** mostrando resultados
3. **POIs cercanos** con marcadores
4. **Ruta calculada** con línea azul
5. **Detalles del lugar** en bottom sheet

---

## 💡 Tips

- **Caché de tiles**: Los tiles se cachean automáticamente
- **Offline**: Considera `flutter_offline_maps` para mapas offline
- **Personalización**: Puedes cambiar colores de rutas, marcadores, etc.
- **Performance**: Limita el número de marcadores mostrados simultáneamente

---

## 🔗 Recursos Adicionales

- **Documentación OSM**: https://wiki.openstreetmap.org/
- **Etiquetas OSM**: https://taginfo.openstreetmap.org/
- **flutter_map docs**: https://docs.fleaflet.dev/
- **OSRM API**: http://project-osrm.org/docs/v5.24.0/api/
