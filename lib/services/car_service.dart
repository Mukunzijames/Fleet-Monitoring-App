import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/car.dart';

class CarService {
  // The provided API endpoint doesn't seem to be working
  // Using a mock implementation instead
  static const String apiUrl = 'https://682d05d64fae18894754a65a.mockapi.io/cars/';
  static const String cacheKey = 'cached_car_data';
  
  // Mock data for our simulation
  final List<Car> _mockCars = [
    Car(id: 1, name: 'Car A', latitude: -1.94995, longitude: 30.05885, speed: 45, status: 'Moving'),
    Car(id: 2, name: 'Car B', latitude: -1.94955, longitude: 30.05825, speed: 0, status: 'Parked'),
    Car(id: 3, name: 'Car C', latitude: -1.95105, longitude: 30.05785, speed: 35, status: 'Moving'),
    Car(id: 4, name: 'Car D', latitude: -1.95205, longitude: 30.05685, speed: 0, status: 'Parked'),
    Car(id: 5, name: 'Car E', latitude: -1.94855, longitude: 30.05985, speed: 25, status: 'Moving'),
  ];
  
  // Define routes for moving cars to follow
  final Map<int, List<LatLng>> _routes = {
    1: [
      LatLng(-1.94995, 30.05885),
      LatLng(-1.95050, 30.05950),
      LatLng(-1.95100, 30.06050),
      LatLng(-1.95050, 30.06150),
      LatLng(-1.94950, 30.06100),
      LatLng(-1.94900, 30.06000),
      LatLng(-1.94950, 30.05900),
    ],
    3: [
      LatLng(-1.95105, 30.05785),
      LatLng(-1.95050, 30.05700),
      LatLng(-1.94950, 30.05650),
      LatLng(-1.94850, 30.05700),
      LatLng(-1.94800, 30.05800),
      LatLng(-1.94850, 30.05900),
      LatLng(-1.95000, 30.05850),
    ],
    5: [
      LatLng(-1.94855, 30.05985),
      LatLng(-1.94800, 30.06050),
      LatLng(-1.94750, 30.06150),
      LatLng(-1.94800, 30.06250),
      LatLng(-1.94900, 30.06300),
      LatLng(-1.95000, 30.06250),
      LatLng(-1.95050, 30.06150),
    ],
  };
  
  // Keep track of current route position for each car
  final Map<int, int> _routePositions = {
    1: 0,
    3: 0,
    5: 0,
  };
  
  final Random _random = Random();
  int _updateCount = 0;

  // Fetch cars - simulates API call
  Future<List<Car>> fetchCars() async {
    try {
      // Try to fetch from real API first (this will likely fail)
      final response = await http.get(Uri.parse(apiUrl)).timeout(
        const Duration(seconds: 3),
        onTimeout: () => throw Exception('Connection timeout'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final cars = jsonData.map((data) => Car.fromJson(data)).toList();
        
        // Cache the data
        _cacheCarData(cars);
        
        print('Fetched ${cars.length} cars from API');
        return cars;
      } else {
        // If API fails, use our mock implementation
        print('API error: ${response.statusCode}, using mock data');
        return _getMockCars();
      }
    } catch (e) {
      // In case of network error, use mock implementation
      print('Network error: $e, using mock data');
      return _getMockCars();
    }
  }

  // Get mock cars with simulated movement
  Future<List<Car>> _getMockCars() async {
    List<Car> carsToUpdate = [];
    
    try {
      // Try to get cached data first
      final cachedCars = await getCachedCars();
      if (cachedCars.isNotEmpty) {
        print('Using cached data: ${cachedCars.length} cars');
        carsToUpdate = cachedCars;
      } else {
        // Use initial mock data
        print('Using initial mock data');
        carsToUpdate = List.from(_mockCars);
      }
    } catch (e) {
      print('Cache error: $e, using initial mock data');
      carsToUpdate = List.from(_mockCars);
    }
    
    // Update car positions based on routes or random movement
    final updatedCars = _updateCarPositions(carsToUpdate);
    
    // Cache the updated cars for next time
    _cacheCarData(updatedCars);
    
    // Increment update counter
    _updateCount++;
    
    return updatedCars;
  }
  
  // Update car positions to simulate movement
  List<Car> _updateCarPositions(List<Car> cars) {
    return cars.map((car) {
      // If car has a predefined route
      if (_routes.containsKey(car.id) && car.status.toLowerCase() == 'moving') {
        final route = _routes[car.id]!;
        int currentPos = _routePositions[car.id]!;
        int nextPos = (currentPos + 1) % route.length;
        
        // Update route position
        _routePositions[car.id] = nextPos;
        
        // Calculate speed based on distance
        final double distance = _calculateDistance(
          route[currentPos].latitude, 
          route[currentPos].longitude,
          route[nextPos].latitude, 
          route[nextPos].longitude
        );
        
        final int newSpeed = (distance * 100000).round();
        
        // Return car with updated position
        return car.copyWith(
          latitude: route[nextPos].latitude,
          longitude: route[nextPos].longitude,
          speed: newSpeed.clamp(20, 60),
        );
      } else if (car.status.toLowerCase() == 'moving') {
        // For moving cars without routes, update position slightly
        final latChange = (_random.nextDouble() - 0.5) * 0.0005;
        final lngChange = (_random.nextDouble() - 0.5) * 0.0005;
        final newSpeed = max(15, min(60, car.speed + (_random.nextInt(11) - 5)));
        
        return car.copyWith(
          latitude: car.latitude + latChange,
          longitude: car.longitude + lngChange,
          speed: newSpeed,
        );
      } else {
        // Randomly change some parked cars to moving and vice versa
        if (_updateCount % 5 == 0 && _random.nextInt(10) == 0) {
          return car.copyWith(
            status: 'Moving',
            speed: 15 + _random.nextInt(20),
          );
        } else if (_updateCount % 7 == 0 && _random.nextInt(15) == 0 && car.status.toLowerCase() == 'moving') {
          return car.copyWith(
            status: 'Parked',
            speed: 0,
          );
        }
      }
      return car;
    }).toList();
  }
  
  // Calculate distance between two points using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // in kilometers
    
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double a = 
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * 
        sin(dLon / 2) * sin(dLon / 2);
        
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c; // distance in km
  }
  
  // Convert degrees to radians
  double _toRadians(double degree) {
    return degree * (pi / 180);
  }

  // Cache car data locally
  Future<void> _cacheCarData(List<Car> cars) async {
    final prefs = await SharedPreferences.getInstance();
    final carListJson = cars.map((car) => car.toJson()).toList();
    await prefs.setString(cacheKey, json.encode(carListJson));
  }

  // Get cached car data
  Future<List<Car>> getCachedCars() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(cacheKey);
    
    if (cachedData != null) {
      final List<dynamic> jsonData = json.decode(cachedData);
      return jsonData.map((data) => Car.fromJson(data)).toList();
    }
    
    return [];
  }

  // Stream for real-time updates
  Stream<List<Car>> getCarUpdates() {
    return Stream.periodic(const Duration(seconds: 5), (_) => fetchCars())
      .asyncMap((future) => future);
  }
} 