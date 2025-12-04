import 'package:flutter/material.dart';

/// Widget para seleccionar el modo de transporte para rutas
class TransportModeSelector extends StatelessWidget {
  final String selectedMode;
  final Function(String) onModeChanged;

  const TransportModeSelector({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildModeButton(
            icon: Icons.directions_car,
            label: 'Coche',
            mode: 'car',
            context: context,
          ),
          _buildModeButton(
            icon: Icons.directions_bike,
            label: 'Bici',
            mode: 'bike',
            context: context,
          ),
          _buildModeButton(
            icon: Icons.directions_walk,
            label: 'Caminar',
            mode: 'foot',
            context: context,
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required IconData icon,
    required String label,
    required String mode,
    required BuildContext context,
  }) {
    final isSelected = selectedMode == mode;
    
    return InkWell(
      onTap: () => onModeChanged(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).primaryColor 
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[700],
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Clase helper para obtener iconos y colores por modo de transporte
class TransportMode {
  static IconData getIcon(String mode) {
    switch (mode) {
      case 'car':
        return Icons.directions_car;
      case 'bike':
        return Icons.directions_bike;
      case 'foot':
        return Icons.directions_walk;
      default:
        return Icons.directions;
    }
  }

  static Color getColor(String mode) {
    switch (mode) {
      case 'car':
        return Colors.blue;
      case 'bike':
        return Colors.green;
      case 'foot':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  static String getLabel(String mode) {
    switch (mode) {
      case 'car':
        return 'En coche';
      case 'bike':
        return 'En bicicleta';
      case 'foot':
        return 'Caminando';
      default:
        return 'Ruta';
    }
  }
}
