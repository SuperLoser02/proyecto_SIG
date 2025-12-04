import 'package:latlong2/latlong.dart';

/// Modelo para representar un lugar (resultado de Nominatim)
class Place {
  final String displayName;
  final LatLng location;
  final String? type;
  final Map<String, dynamic>? address;

  Place({
    required this.displayName,
    required this.location,
    this.type,
    this.address,
  });

  factory Place.fromNominatimJson(Map<String, dynamic> json) {
    return Place(
      displayName: json['display_name'] ?? '',
      location: LatLng(
        double.parse(json['lat'].toString()),
        double.parse(json['lon'].toString()),
      ),
      type: json['type'],
      address: json['address'],
    );
  }

  String get shortName {
    if (address != null) {
      return address!['name'] ?? 
             address!['road'] ?? 
             address!['suburb'] ?? 
             displayName.split(',').first;
    }
    return displayName.split(',').first;
  }
}
