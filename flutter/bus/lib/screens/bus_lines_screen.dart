import 'package:flutter/material.dart';
import '../models/bus_line.dart';
import '../services/bus_line_service.dart';

class BusLinesScreen extends StatefulWidget {
  const BusLinesScreen({super.key});

  @override
  State<BusLinesScreen> createState() => _BusLinesScreenState();
}

class _BusLinesScreenState extends State<BusLinesScreen> {
  final _busService = BusLineService.instance;
  List<BusLine> _busLines = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadLines();
  }

  Future<void> _loadLines() async {
    try {
      await _busService.loadData();
      setState(() {
        _busLines = _busService.getAllLines();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Líneas de Micro'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadLines,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _busLines.length,
                  itemBuilder: (context, index) {
                    final line = _busLines[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.transparent,
                          child: Image.asset(
                            'assets/imagenes_lineas/img_${line.displayName}.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.image_not_supported, color: Colors.red);
                            },
                          ),
                        ),
                        title: Text(
                          line.displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  BusLineDetailScreen(busLine: line),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

class BusLineDetailScreen extends StatefulWidget {
  final BusLine busLine;

  const BusLineDetailScreen({super.key, required this.busLine});

  @override
  State<BusLineDetailScreen> createState() => _BusLineDetailScreenState();
}

class _BusLineDetailScreenState extends State<BusLineDetailScreen> {
  final _busService = BusLineService.instance;
  List<BusRoute> _routes = [];

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  void _loadRoutes() {
    setState(() {
      _routes = _busService.getRoutesForBusLine(widget.busLine.idLinea);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Línea ${widget.busLine.displayName}'),
        backgroundColor: widget.busLine.color,
        foregroundColor: Colors.white,
      ),
      body: _routes.isEmpty
          ? const Center(
              child: Text('No hay rutas disponibles para esta línea'),
            )
          : ListView.builder(
              itemCount: _routes.length,
              itemBuilder: (context, index) {
                final route = _routes[index];
                return Card(
                  margin: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: widget.busLine.color.withValues(alpha: 0.1),
                        child: Row(
                          children: [
                            Icon(
                              route.isSalida
                                  ? Icons.arrow_forward
                                  : Icons.arrow_back,
                              color: widget.busLine.color,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                route.description,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.straighten, size: 20),
                                const SizedBox(width: 8),
                                Text('Distancia: ${route.formattedDistance}'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 20),
                                const SizedBox(width: 8),
                                Text('Tiempo: ${route.formattedTime}'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 20),
                                const SizedBox(width: 8),
                                Text('Puntos: ${route.points.length}'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pop(context, route);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: widget.busLine.color,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.map),
                                label: const Text('Ver en Mapa'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
