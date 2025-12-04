import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

class BusLine {
  final int idLinea;
  final String nombreLinea;
  final String colorLinea;
  final String? imagenLinea; // Nullable porque puede ser null en DB
  final String? fechaCreacion; // Nullable porque puede ser null en DB

  BusLine({
    required this.idLinea,
    required this.nombreLinea,
    required this.colorLinea,
    this.imagenLinea,
    this.fechaCreacion,
  });

  factory BusLine.fromJson(Map<String, dynamic> json) {
    return BusLine(
      idLinea: json['id'] as int, // Django usa 'id' auto-generado
      nombreLinea: (json['nombreLinea'] as String).trim(),
      colorLinea: json['colorLinea'] as String,
      imagenLinea: json['imagenLinea'] as String?, // Cambio: imagenLinea no imagenMicrobus
      fechaCreacion: json['fechaCreacion'] as String?,
    );
  }

  String get displayName => nombreLinea.trim();
  
  Color get color {
    try {
      return Color(int.parse(colorLinea.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.red;
    }
  }
}

class LineaRuta {
  final int idLineaRuta;
  final int idLinea; // FK - Django envía solo el ID
  final String idRuta; // IMPORTANTE: Django lo tiene como CharField (String)
  final String? descripcion;
  final double? distancia;
  final double? tiempo;

  LineaRuta({
    required this.idLineaRuta,
    required this.idLinea,
    required this.idRuta,
    this.descripcion,
    this.distancia,
    this.tiempo,
  });

  factory LineaRuta.fromJson(Map<String, dynamic> json) {
    return LineaRuta(
      idLineaRuta: json['id'] as int, // Django usa 'id' auto-generado
      idLinea: json['idlinea'] as int, // FK - Django envía solo el ID con este nombre
      idRuta: json['idRuta'] as String, // String, no int
      descripcion: json['descripcion'] != null 
          ? (json['descripcion'] as String).trim() 
          : null,
      distancia: json['distancia'] != null 
          ? (json['distancia'] as num).toDouble() 
          : null,
      tiempo: json['tiempo'] != null 
          ? (json['tiempo'] as num).toDouble() 
          : null,
    );
  }

  String get formattedDistance {
    if (distancia == null) return 'N/A';
    if (distancia! < 1) {
      return '${(distancia! * 1000).toStringAsFixed(0)} m';
    }
    return '${distancia!.toStringAsFixed(2)} km';
  }

  String get formattedTime {
    if (tiempo == null) return 'N/A';
    final hours = tiempo!.floor();
    final minutes = ((tiempo! - hours) * 60).round();
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }
}

class BusPoint {
  final int idPunto;
  final double latitud;
  final double longitud;
  final String? descripcion;

  BusPoint({
    required this.idPunto,
    required this.latitud,
    required this.longitud,
    this.descripcion,
  });

  factory BusPoint.fromJson(Map<String, dynamic> json) {
    return BusPoint(
      idPunto: json['id'] as int, // Django usa 'id' auto-generado
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
      descripcion: json['descripcion'] != null
          ? (json['descripcion'] as String).trim()
          : null,
    );
  }

  LatLng get location => LatLng(latitud, longitud);
}

class BusLinePoint {
  final int idLineaPunto;
  final int idLineaRuta; // FK - Django envía solo el ID
  final int idPunto; // FK - Django envía solo el ID
  final int orden;
  final double latitud;
  final double longitud;
  final double? distancia;
  final double? tiempo;

  BusLinePoint({
    required this.idLineaPunto,
    required this.idLineaRuta,
    required this.idPunto,
    required this.orden,
    required this.latitud,
    required this.longitud,
    this.distancia,
    this.tiempo,
  });

  factory BusLinePoint.fromJson(Map<String, dynamic> json) {
    return BusLinePoint(
      idLineaPunto: json['id'] as int, // Django usa 'id' auto-generado
      idLineaRuta: json['idLineaRuta'] as int, // FK - Django envía solo el ID
      idPunto: json['idPunto'] as int, // FK - Django envía solo el ID
      orden: json['orden'] as int,
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
      distancia: json['distancia'] != null 
          ? (json['distancia'] as num).toDouble() 
          : null,
      tiempo: json['tiempo'] != null 
          ? (json['tiempo'] as num).toDouble() 
          : null,
    );
  }

  LatLng get location => LatLng(latitud, longitud);
}

class BusRoute {
  final BusLine line;
  final LineaRuta lineaRuta;
  final List<BusLinePoint> points;

  BusRoute({
    required this.line,
    required this.lineaRuta,
    required this.points,
  });

  List<LatLng> get coordinates => points.map((p) => p.location).toList();

  String get description => lineaRuta.descripcion ?? '';
  double get totalDistance => lineaRuta.distancia ?? 0.0;
  double get totalTime => lineaRuta.tiempo ?? 0.0;
  
  String get formattedDistance => lineaRuta.formattedDistance;
  String get formattedTime => lineaRuta.formattedTime;
  
  bool get isSalida => description.contains('Salida');
  bool get isRetorno => description.contains('Retorno');
}