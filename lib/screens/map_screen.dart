import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/car_provider.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/map_placeholder_widget.dart';
import 'car_details_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(-1.9500, 30.0588), // Rwanda coordinates
    zoom: 14.0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<CarProvider>(
        builder: (context, carProvider, child) {
          if (carProvider.isLoading && carProvider.cars.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (carProvider.hasError && carProvider.cars.isEmpty) {
            return CustomErrorWidget(
              message: carProvider.errorMessage,
              onRetry: () => carProvider.fetchCars(),
            );
          }
          
          return Stack(
            children: [
              // Google Map or Placeholder
              Positioned.fill(
                child: _buildMapWidget(carProvider),
              ),
              
              // Search and filter UI
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SearchBarWidget(
                        onSearch: carProvider.setSearchQuery,
                        searchQuery: carProvider.searchQuery,
                      ),
                    ),
                    
                    // Filter chips
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChipWidget(
                              label: 'All',
                              isSelected: carProvider.statusFilter.isEmpty,
                              onSelected: (_) => carProvider.setStatusFilter(''),
                            ),
                            const SizedBox(width: 8),
                            FilterChipWidget(
                              label: 'Moving',
                              isSelected: carProvider.statusFilter.toLowerCase() == 'moving',
                              onSelected: (_) => carProvider.setStatusFilter('Moving'),
                            ),
                            const SizedBox(width: 8),
                            FilterChipWidget(
                              label: 'Parked',
                              isSelected: carProvider.statusFilter.toLowerCase() == 'parked',
                              onSelected: (_) => carProvider.setStatusFilter('Parked'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Bottom status bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cars: ${carProvider.filteredCars.length}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.directions_car,
                              size: 16,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Moving: ${carProvider.filteredCars.where((car) => car.status.toLowerCase() == 'moving').length}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.directions_car,
                              size: 16,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Parked: ${carProvider.filteredCars.where((car) => car.status.toLowerCase() == 'parked').length}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final provider = Provider.of<CarProvider>(context, listen: false);
          await provider.fetchCars();
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildMapWidget(CarProvider carProvider) {
    // For web, show a placeholder instead of Google Maps
    if (kIsWeb) {
      return MapPlaceholderWidget(cars: carProvider.filteredCars);
    }
    
    // For mobile platforms, show the actual Google Map
    return GoogleMap(
      initialCameraPosition: _initialPosition,
      markers: carProvider.markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
      zoomControlsEnabled: false,
      onMapCreated: (GoogleMapController controller) {
        _mapController.complete(controller);
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // Listen for selected car changes to navigate to details screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final carProvider = Provider.of<CarProvider>(context, listen: false);
      carProvider.addListener(() {
        if (carProvider.selectedCar != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CarDetailsScreen(car: carProvider.selectedCar!),
            ),
          ).then((_) => carProvider.clearSelectedCar());
        }
      });
    });
  }
} 