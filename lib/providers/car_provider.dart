import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/car.dart';
import '../services/car_service.dart';

class CarProvider extends ChangeNotifier {
  final CarService _carService = CarService();
  List<Car> _cars = [];
  List<Car> _filteredCars = [];
  Map<int, Marker> _markers = {};
  Map<int, Car> _previousPositions = {};
  String _searchQuery = '';
  String _statusFilter = '';
  Car? _selectedCar;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  StreamSubscription<List<Car>>? _carUpdateSubscription;
  
  // Getters
  List<Car> get cars => _cars;
  List<Car> get filteredCars => _filteredCars;
  Set<Marker> get markers => _markers.values.toSet();
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  Car? get selectedCar => _selectedCar;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;
  
  CarProvider() {
    _initializeData();
  }
  
  void _initializeData() async {
    await fetchCars();
    startRealTimeUpdates();
  }
  
  // Fetch cars from the service
  Future<void> fetchCars() async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();
    
    try {
      _cars = await _carService.fetchCars();
      
      // Store current positions for animation
      for (var car in _cars) {
        _previousPositions[car.id] = car;
      }
      
      _applyFilters();
      _updateMarkers();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _hasError = true;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
  
  // Start real-time updates
  void startRealTimeUpdates() {
    _carUpdateSubscription?.cancel();
    _carUpdateSubscription = _carService.getCarUpdates().listen(
      (updatedCars) {
        // Store previous positions for animation
        for (var car in _cars) {
          _previousPositions[car.id] = car;
        }
        
        _cars = updatedCars;
        _applyFilters();
        _updateMarkersWithAnimation();
        notifyListeners();
      },
      onError: (e) {
        _hasError = true;
        _errorMessage = e.toString();
        notifyListeners();
      }
    );
  }
  
  // Apply search and status filters
  void _applyFilters() {
    _filteredCars = _cars.where((car) {
      final matchesSearch = _searchQuery.isEmpty || 
          car.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          car.id.toString().contains(_searchQuery);
          
      final matchesStatus = _statusFilter.isEmpty || 
          car.status.toLowerCase() == _statusFilter.toLowerCase();
          
      return matchesSearch && matchesStatus;
    }).toList();
  }
  
  // Update map markers based on filtered cars
  void _updateMarkers() {
    _markers = {};
    
    for (final car in _filteredCars) {
      final markerId = MarkerId(car.id.toString());
      
      _markers[car.id] = Marker(
        markerId: markerId,
        position: car.position,
        infoWindow: InfoWindow(
          title: car.name,
          snippet: '${car.speed} km/h - ${car.status}'
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          car.status.toLowerCase() == 'moving' 
              ? BitmapDescriptor.hueGreen 
              : BitmapDescriptor.hueRed
        ),
        onTap: () {
          selectCar(car);
        }
      );
    }
  }
  
  // Update markers with smooth animation
  void _updateMarkersWithAnimation() {
    for (final car in _filteredCars) {
      final markerId = MarkerId(car.id.toString());
      final previousCar = _previousPositions[car.id];
      
      // Only animate if we have a previous position and it's different
      if (previousCar != null && 
          (previousCar.latitude != car.latitude || 
           previousCar.longitude != car.longitude)) {
        
        _markers[car.id] = Marker(
          markerId: markerId,
          position: car.position,
          infoWindow: InfoWindow(
            title: car.name,
            snippet: '${car.speed} km/h - ${car.status}'
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            car.status.toLowerCase() == 'moving' 
                ? BitmapDescriptor.hueGreen 
                : BitmapDescriptor.hueRed
          ),
          onTap: () {
            selectCar(car);
          },
          // Add rotation based on movement direction
          rotation: _calculateRotation(previousCar, car),
          // Add smooth animation for marker movement
          flat: car.status.toLowerCase() == 'moving',
        );
      } else {
        // For new cars or stationary cars
        _markers[car.id] = Marker(
          markerId: markerId,
          position: car.position,
          infoWindow: InfoWindow(
            title: car.name,
            snippet: '${car.speed} km/h - ${car.status}'
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            car.status.toLowerCase() == 'moving' 
                ? BitmapDescriptor.hueGreen 
                : BitmapDescriptor.hueRed
          ),
          onTap: () {
            selectCar(car);
          },
        );
      }
    }
  }
  
  // Calculate rotation angle based on movement direction
  double _calculateRotation(Car previousPosition, Car currentPosition) {
    if (previousPosition.latitude == currentPosition.latitude && 
        previousPosition.longitude == currentPosition.longitude) {
      return 0.0;
    }
    
    // Calculate the bearing between two points
    final double lat1 = previousPosition.latitude * (pi / 180);
    final double lon1 = previousPosition.longitude * (pi / 180);
    final double lat2 = currentPosition.latitude * (pi / 180);
    final double lon2 = currentPosition.longitude * (pi / 180);
    
    final double dLon = lon2 - lon1;
    
    final double y = sin(dLon) * cos(lat2);
    final double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    
    final double bearing = atan2(y, x) * (180 / pi);
    return (bearing + 360) % 360;
  }
  
  // Set the selected car
  void selectCar(Car car) {
    _selectedCar = car;
    notifyListeners();
  }
  
  // Clear the selected car
  void clearSelectedCar() {
    _selectedCar = null;
    notifyListeners();
  }
  
  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    _updateMarkers();
    notifyListeners();
  }
  
  // Set status filter
  void setStatusFilter(String status) {
    _statusFilter = status;
    _applyFilters();
    _updateMarkers();
    notifyListeners();
  }
  
  // Clear filters
  void clearFilters() {
    _searchQuery = '';
    _statusFilter = '';
    _applyFilters();
    _updateMarkers();
    notifyListeners();
  }
  
  @override
  void dispose() {
    _carUpdateSubscription?.cancel();
    super.dispose();
  }
} 