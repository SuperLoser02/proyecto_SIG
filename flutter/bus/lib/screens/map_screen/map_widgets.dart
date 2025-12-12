import 'package:flutter/material.dart';
import '../../models/place.dart';

/// Widget de barra de búsqueda
class SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSearching;
  final Function(String) onChanged;
  final VoidCallback onClear;

  const SearchBar({
    super.key,
    required this.controller,
    required this.isSearching,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Buscar lugar en Santa Cruz...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: isSearching
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : controller.text.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear), onPressed: onClear)
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

/// Widget de resultados de búsqueda
class SearchResults extends StatelessWidget {
  final List<Place> results;
  final Function(Place) onPlaceSelected;

  const SearchResults({
    super.key,
    required this.results,
    required this.onPlaceSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 300),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: results.length,
          itemBuilder: (context, index) {
            final place = results[index];
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
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => onPlaceSelected(place),
            );
          },
        ),
      ),
    );
  }
}

/// Banner de modo de selección activo
class SelectionModeBanner extends StatelessWidget {
  final bool isSelectingOrigin;
  final VoidCallback onClose;

  const SelectionModeBanner({
    super.key,
    required this.isSelectingOrigin,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final bannerColor = isSelectingOrigin ? Colors.green : Colors.blue;
    final title = isSelectingOrigin
        ? 'Seleccionar Origen'
        : 'Seleccionar Destino';
    final description = isSelectingOrigin
        ? 'Toca un punto del mapa para establecer tu punto de origen'
        : 'Toca un punto del mapa para establecer tu destino';

    return Card(
      color: bannerColor.shade50,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.touch_app, color: bannerColor.shade700, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: bannerColor.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 13, color: bannerColor.shade700),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: bannerColor.shade700),
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}

/// Botones flotantes de acción
class MapActionButtons extends StatelessWidget {
  final bool isSelectingOrigin;
  final bool isSelectingDestination;
  final bool isLoadingLocation;
  final VoidCallback onToggleOriginSelection;
  final VoidCallback onToggleDestinationSelection;
  final VoidCallback onShowBusLines;
  final VoidCallback onGetLocation;
  final VoidCallback onShowNearby;

  const MapActionButtons({
    super.key,
    required this.isSelectingOrigin,
    required this.isSelectingDestination,
    required this.isLoadingLocation,
    required this.onToggleOriginSelection,
    required this.onToggleDestinationSelection,
    required this.onShowBusLines,
    required this.onGetLocation,
    required this.onShowNearby,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FloatingActionButton.extended(
          heroTag: 'select_origin',
          backgroundColor: isSelectingOrigin ? Colors.orange : Colors.green,
          onPressed: onToggleOriginSelection,
          icon: Icon(isSelectingOrigin ? Icons.touch_app : Icons.trip_origin),
          label: Text(isSelectingOrigin ? 'Seleccionando...' : 'Origen'),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.extended(
          heroTag: 'select_destination',
          backgroundColor: isSelectingDestination ? Colors.orange : Colors.blue,
          onPressed: onToggleDestinationSelection,
          icon: Icon(
            isSelectingDestination ? Icons.touch_app : Icons.add_location,
          ),
          label: Text(isSelectingDestination ? 'Seleccionando...' : 'Destino'),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: 'bus_lines',
          backgroundColor: Colors.orange,
          onPressed: onShowBusLines,
          child: const Icon(Icons.directions_bus),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: 'location',
          onPressed: onGetLocation,
          child: isLoadingLocation
              ? const CircularProgressIndicator(color: Colors.white)
              : const Icon(Icons.my_location),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: 'nearby',
          onPressed: onShowNearby,
          child: const Icon(Icons.near_me),
        ),
      ],
    );
  }
}
