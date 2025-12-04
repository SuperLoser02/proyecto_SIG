import 'package:flutter/material.dart';

/// Categorías de lugares disponibles en Overpass API
class POICategory {
  final String name;
  final String query;
  final IconData icon;
  final Color color;

  const POICategory({
    required this.name,
    required this.query,
    required this.icon,
    required this.color,
  });

  static const List<POICategory> categories = [
    POICategory(
      name: 'Restaurantes',
      query: 'amenity=restaurant',
      icon: Icons.restaurant,
      color: Colors.orange,
    ),
    POICategory(
      name: 'Farmacias',
      query: 'amenity=pharmacy',
      icon: Icons.local_pharmacy,
      color: Colors.green,
    ),
    POICategory(
      name: 'Paradas de bus',
      query: 'highway=bus_stop',
      icon: Icons.directions_bus,
      color: Colors.blue,
    ),
    POICategory(
      name: 'Cajeros ATM',
      query: 'amenity=atm',
      icon: Icons.atm,
      color: Colors.teal,
    ),
    POICategory(
      name: 'Hospitales',
      query: 'amenity=hospital',
      icon: Icons.local_hospital,
      color: Colors.red,
    ),
    POICategory(
      name: 'Supermercados',
      query: 'shop=supermarket',
      icon: Icons.shopping_cart,
      color: Colors.purple,
    ),
    POICategory(
      name: 'Gasolineras',
      query: 'amenity=fuel',
      icon: Icons.local_gas_station,
      color: Colors.amber,
    ),
    POICategory(
      name: 'Bancos',
      query: 'amenity=bank',
      icon: Icons.account_balance,
      color: Colors.indigo,
    ),
    POICategory(
      name: 'Cafeterías',
      query: 'amenity=cafe',
      icon: Icons.local_cafe,
      color: Colors.brown,
    ),
    POICategory(
      name: 'Parques',
      query: 'leisure=park',
      icon: Icons.park,
      color: Colors.lightGreen,
    ),
  ];
}
