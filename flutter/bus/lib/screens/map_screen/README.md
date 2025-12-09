# Map Screen - Estructura Refactorizada

Este directorio contiene la implementación modular de la pantalla de mapa (`MapScreen`).

## 📁 Estructura de Archivos

```
map_screen/
├── map_state.dart              # Estado compartido del mapa
├── location_handler.dart       # Manejo de ubicación GPS
├── search_handler.dart         # Búsqueda de lugares
├── bus_route_handler.dart      # Búsqueda y visualización de rutas de micro
├── destination_selector.dart   # Selección manual de destino en el mapa
├── poi_handler.dart           # Manejo de puntos de interés (POI)
└── map_widgets.dart           # Widgets reutilizables (SearchBar, Botones, etc.)
```

## 🎯 Responsabilidades de Cada Archivo

### `map_state.dart`
Estado centralizado que contiene:
- Controladores del mapa y búsqueda
- Ubicación actual del usuario
- Marcadores y polylines
- Estados de carga y selección

### `location_handler.dart`
Maneja la ubicación del usuario:
- Obtener ubicación GPS actual
- Actualizar ubicación sin mover el mapa
- Centrar el mapa en la ubicación del usuario

### `search_handler.dart`
Búsqueda de lugares por texto:
- Buscar lugares usando Nominatim
- Seleccionar un lugar de los resultados
- Limpiar resultados de búsqueda

### `bus_route_handler.dart`
Rutas de micro:
- Buscar rutas de micro hacia un destino
- Mostrar ruta recomendada con marcadores
- Visualizar rutas de micro desde la lista

### `destination_selector.dart`
Selección manual en el mapa:
- Activar/desactivar modo de selección
- Seleccionar destino con un toque en el mapa
- Mostrar diálogo de confirmación

### `poi_handler.dart`
Puntos de interés:
- Buscar POIs cercanos (restaurantes, bancos, etc.)
- Mostrar detalles de un POI
- Calcular ruta en auto hacia un POI

### `map_widgets.dart`
Widgets reutilizables:
- `SearchBar` - Barra de búsqueda con loader
- `SearchResults` - Lista de resultados de búsqueda
- `SelectionModeBanner` - Banner informativo de modo de selección
- `MapActionButtons` - Botones flotantes de acción

## 🔄 Flujo de Datos

1. **Estado Central**: `MapState` contiene todos los datos compartidos
2. **Handlers**: Cada handler modifica el estado a través de callbacks
3. **Actualización**: Los handlers llaman a `onUpdate()` para refrescar la UI
4. **Context**: Los handlers que necesitan mostrar diálogos reciben el `BuildContext`

## 🚀 Ventajas de Esta Estructura

- ✅ **Separación de responsabilidades**: Cada archivo tiene un propósito claro
- ✅ **Mantenibilidad**: Fácil encontrar y modificar funcionalidad específica
- ✅ **Testeable**: Los handlers pueden ser testeados independientemente
- ✅ **Reutilizable**: Los widgets pueden usarse en otras pantallas
- ✅ **Escalable**: Agregar nuevas funcionalidades es más sencillo

## 📝 Cómo Agregar Nueva Funcionalidad

1. Crear un nuevo handler en `map_screen/`
2. Agregar el handler en `_MapScreenState`
3. Inicializarlo en `_initializeHandlers()`
4. Usarlo donde sea necesario

Ejemplo:
```dart
// 1. Crear traffic_handler.dart
class TrafficHandler {
  final MapState state;
  final VoidCallback onUpdate;
  // ...
}

// 2. En map_screen.dart
late final TrafficHandler _trafficHandler;

// 3. Inicializar
_trafficHandler = TrafficHandler(
  state: _state,
  onUpdate: () => setState(() {}),
);
```
