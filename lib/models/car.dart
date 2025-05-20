import 'package:google_maps_flutter/google_maps_flutter.dart';

class Car {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final int speed;
  final String status;
  
  // Computed property for the car's position as a LatLng object
  LatLng get position => LatLng(latitude, longitude);

  Car({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.status,
  });

  // Factory constructor to create a Car from JSON
  factory Car.fromJson(Map<String, dynamic> json) {
    // Handle different possible formats from the API
    return Car(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      name: json['name'] ?? 'Unknown Car',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      speed: json['speed'] is String ? int.parse(json['speed']) : (json['speed'] ?? 0),
      status: json['status'] ?? 'Unknown',
    );
  }

  // Helper method to parse double values from API
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Convert the Car object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'status': status,
    };
  }

  // Create a copy of the car with updated properties
  Car copyWith({
    int? id,
    String? name,
    double? latitude,
    double? longitude,
    int? speed,
    String? status,
  }) {
    return Car(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speed: speed ?? this.speed,
      status: status ?? this.status,
    );
  }
} 