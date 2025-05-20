import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/car.dart';
import '../providers/car_provider.dart';

class MapPlaceholderWidget extends StatelessWidget {
  final List<Car> cars;

  const MapPlaceholderWidget({
    super.key,
    required this.cars,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // Map background pattern
          Positioned.fill(
            child: CustomPaint(
              painter: GridPainter(),
            ),
          ),
          
          // Cars representation
          ...cars.map((car) => _buildCarMarker(car, context)).toList(),
          
          // Compass in the corner
          Positioned(
            top: 100,
            right: 20,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.navigation,
                  size: 30,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
          
          // Web notice
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'Map View (Web Preview Mode)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarMarker(Car car, BuildContext context) {
    // Convert latitude and longitude to pixel positions
    // This is a simplified mapping for demonstration purposes
    // In a real app, you would use proper geo mapping
    
    // Map coordinates to positions in the container
    // Adjust these values based on your specific data range
    const double minLat = -1.9600;
    const double maxLat = -1.9400;
    const double minLng = 30.0500;
    const double maxLng = 30.0700;
    
    // Calculate relative position (0.0 to 1.0)
    final double relX = (car.longitude - minLng) / (maxLng - minLng);
    final double relY = (car.latitude - minLat) / (maxLat - minLat);
    
    // Ensure positions are within bounds
    final safeRelX = relX.clamp(0.1, 0.9);
    final safeRelY = relY.clamp(0.1, 0.9);
    
    return Positioned(
      left: MediaQuery.of(context).size.width * safeRelX - 25, // Center the marker (width/2)
      top: MediaQuery.of(context).size.height * safeRelY - 25, // Center the marker (height/2)
      child: GestureDetector(
        onTap: () {
          // Trigger selection in the provider
          Provider.of<CarProvider>(context, listen: false).selectCar(car);
        },
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: car.status.toLowerCase() == 'moving'
                ? Colors.green.withOpacity(0.8)
                : Colors.red.withOpacity(0.8),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.directions_car,
                  color: Colors.white,
                  size: 20,
                ),
                Text(
                  car.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom painter to draw a grid pattern for the map background
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1;
    
    // Draw vertical lines
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      x += 50;
    }
    
    // Draw horizontal lines
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += 50;
    }
    
    // Draw some landmarks or points of interest
    final landmarkPaint = Paint()
      ..color = Colors.blue.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    
    // Draw a few circles to represent landmarks
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.4), 80, landmarkPaint);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.6), 120, landmarkPaint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.2), 60, landmarkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 