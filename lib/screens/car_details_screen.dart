import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../models/car.dart';
import '../providers/car_provider.dart';
import '../widgets/map_placeholder_widget.dart';

class CarDetailsScreen extends StatefulWidget {
  final Car car;
  
  const CarDetailsScreen({super.key, required this.car});

  @override
  State<CarDetailsScreen> createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends State<CarDetailsScreen> {
  late GoogleMapController? _mapController;
  bool _isTracking = false;
  Car? _currentCar;
  
  @override
  void initState() {
    super.initState();
    _currentCar = widget.car;
    
    // Listen for updates to this specific car
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final carProvider = Provider.of<CarProvider>(context, listen: false);
      carProvider.addListener(() {
        if (_isTracking) {
          final updatedCar = carProvider.cars.firstWhere(
            (car) => car.id == widget.car.id,
            orElse: () => widget.car,
          );
          
          setState(() {
            _currentCar = updatedCar;
          });
          
          _animateToCurrentPosition();
        }
      });
    });
  }
  
  void _animateToCurrentPosition() {
    if (_currentCar != null && _isTracking && _mapController != null && !kIsWeb) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(_currentCar!.position),
      );
    }
  }
  
  void _toggleTracking() {
    setState(() {
      _isTracking = !_isTracking;
    });
    
    if (_isTracking) {
      _animateToCurrentPosition();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentCar?.name ?? 'Car Details'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Car info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                // Car icon with status indicator
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _currentCar?.status.toLowerCase() == 'moving'
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.directions_car,
                    size: 36,
                    color: _currentCar?.status.toLowerCase() == 'moving'
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                // Car details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentCar?.name ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildInfoItem(
                            icon: Icons.speed,
                            label: '${_currentCar?.speed ?? 0} km/h',
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _currentCar?.status.toLowerCase() == 'moving'
                                  ? Colors.green
                                  : Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _currentCar?.status ?? 'Unknown',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildInfoItem(
                        icon: Icons.location_on,
                        label: 'Lat: ${_currentCar?.latitude.toStringAsFixed(5)}, '
                            'Lng: ${_currentCar?.longitude.toStringAsFixed(5)}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Map showing the car's location
          Expanded(
            child: _buildMapWidget(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleTracking,
        icon: Icon(_isTracking ? Icons.location_disabled : Icons.location_searching),
        label: Text(_isTracking ? 'Stop Tracking' : 'Track This Car'),
        backgroundColor: _isTracking ? Colors.red : Theme.of(context).primaryColor,
      ),
    );
  }
  
  Widget _buildInfoItem({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
  
  Widget _buildMapWidget() {
    if (kIsWeb) {
      // For web, show a placeholder with just this car
      return MapPlaceholderWidget(cars: [_currentCar!]);
    }
    
    // For mobile platforms, show the actual Google Map
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _currentCar?.position ?? const LatLng(0, 0),
        zoom: 16,
      ),
      markers: {
        if (_currentCar != null)
          Marker(
            markerId: MarkerId(_currentCar!.id.toString()),
            position: _currentCar!.position,
            infoWindow: InfoWindow(
              title: _currentCar!.name,
              snippet: '${_currentCar!.speed} km/h - ${_currentCar!.status}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _currentCar!.status.toLowerCase() == 'moving'
                  ? BitmapDescriptor.hueGreen
                  : BitmapDescriptor.hueRed,
            ),
          ),
      },
      onMapCreated: (controller) {
        _mapController = controller;
      },
    );
  }
} 