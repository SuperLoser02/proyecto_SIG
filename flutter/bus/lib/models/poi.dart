import 'package:latlong2/latlong.dart';

/// Modelo para Point of Interest (POI)
class POI {
  final String id;
  final String name;
  final LatLng location;
  final String? type;
  final Map<String, dynamic> tags;

  POI({
    required this.id,
    required this.name,
    required this.location,
    this.type,
    required this.tags,
  });

  factory POI.fromOverpassJson(Map<String, dynamic> json) {
    return POI(
      id: json['id'].toString(),
      name: json['tags']?['name'] ?? 'Sin nombre',
      location: LatLng(
        double.parse(json['lat'].toString()),
        double.parse(json['lon'].toString()),
      ),
      type: json['type'],
      tags: Map<String, dynamic>.from(json['tags'] ?? {}),
    );
  }

  String get category {
    if (tags.containsKey('amenity')) return tags['amenity'];
    if (tags.containsKey('shop')) return tags['shop'];
    if (tags.containsKey('highway')) return tags['highway'];
    return 'place';
  }

  String get address {
    final street = tags['addr:street'] ?? '';
    final number = tags['addr:housenumber'] ?? '';
    if (street.isNotEmpty) {
      return number.isNotEmpty ? '$street $number' : street;
    }
    return '';
  }
}
