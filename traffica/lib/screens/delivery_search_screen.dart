import 'package:flutter/material.dart';
import '../models/delivery_search_result.dart';
import '../widgets/gradient_background.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import '../models/optimal_route_input.dart';

class DeliverySearchScreen extends StatefulWidget {
  @override
  _DeliverySearchScreenState createState() => _DeliverySearchScreenState();
}

class _DeliverySearchScreenState extends State<DeliverySearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<DeliverySearchResult> _searchResults = [];
  bool _isLoading = false;
  Position? _currentPosition;

  // Mock data for Indian cities
  final List<DeliverySearchResult> _mockResults = [
    DeliverySearchResult(
      address: "Connaught Place, New Delhi",
      city: "New Delhi",
      state: "Delhi",
      pincode: "110001",
      latitude: 28.6139,
      longitude: 77.2090,
      deliveryType: "standard",
      deliveryFee: 50.0,
      estimatedTimeMinutes: 120,
    ),
    DeliverySearchResult(
      address: "Marine Drive, Mumbai",
      city: "Mumbai",
      state: "Maharashtra",
      pincode: "400020",
      latitude: 18.9440,
      longitude: 72.8236,
      deliveryType: "express",
      deliveryFee: 75.0,
      estimatedTimeMinutes: 90,
    ),
    DeliverySearchResult(
      address: "Banjara Hills, Hyderabad",
      city: "Hyderabad",
      state: "Telangana",
      pincode: "500034",
      latitude: 17.3850,
      longitude: 78.4867,
      deliveryType: "same_day",
      deliveryFee: 100.0,
      estimatedTimeMinutes: 60,
    ),
    DeliverySearchResult(
      address: "MG Road, Bangalore",
      city: "Bangalore",
      state: "Karnataka",
      pincode: "560001",
      latitude: 12.9716,
      longitude: 77.5946,
      deliveryType: "standard",
      deliveryFee: 60.0,
      estimatedTimeMinutes: 100,
    ),
    DeliverySearchResult(
      address: "T. Nagar, Chennai",
      city: "Chennai",
      state: "Tamil Nadu",
      pincode: "600017",
      latitude: 13.0827,
      longitude: 80.2707,
      deliveryType: "express",
      deliveryFee: 70.0,
      estimatedTimeMinutes: 80,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await LocationService.getCurrentLocation();
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      // Handle error silently for delivery search
    }
  }

  void _searchAddresses(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use API service to search addresses
      final results = await ApiService.instance.searchDeliveryAddresses(query: query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      // Fallback to mock data if API fails
      final filteredResults = _mockResults.where((result) {
        final searchTerm = query.toLowerCase();
        return result.address.toLowerCase().contains(searchTerm) ||
               result.city.toLowerCase().contains(searchTerm) ||
               result.state.toLowerCase().contains(searchTerm) ||
               result.pincode.contains(searchTerm);
      }).toList();

      setState(() {
        _searchResults = filteredResults;
        _isLoading = false;
      });
    }
  }

  String _getDeliveryTypeIcon(String type) {
    switch (type) {
      case 'standard':
        return '🚚';
      case 'express':
        return '⚡';
      case 'same_day':
        return '📦';
      default:
        return '🚚';
    }
  }

  Color _getDeliveryTypeColor(String type) {
    switch (type) {
      case 'standard':
        return Colors.blue;
      case 'express':
        return Colors.orange;
      case 'same_day':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery Partner Search'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: GradientBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Enter delivery location (city, address, pincode)',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                ),
                onChanged: _searchAddresses,
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty && _searchController.text.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_off, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No delivery locations found',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Try searching for a different location',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final result = _searchResults[index];
                            return Card(
                              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.all(16),
                                leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: _getDeliveryTypeColor(result.deliveryType).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _getDeliveryTypeIcon(result.deliveryType),
                                      style: TextStyle(fontSize: 24),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  result.address,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 4),
                                    Text('${result.city}, ${result.state} - ${result.pincode}'),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _getDeliveryTypeColor(result.deliveryType),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            result.deliveryType.toUpperCase(),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          '₹${result.deliveryFee}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          '${result.estimatedTimeMinutes} min',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.arrow_forward_ios),
                                  onPressed: () async {
                                    if (_currentPosition != null) {
                                      try {
                                        // Compute route from current location to delivery destination
                                        final routeResult = await ApiService.instance.getOptimalRoute(
                                          OptimalRouteInput(
                                            fromLocation: 'Current Location',
                                            toLocation: result.address,
                                            time: DateTime.now(),
                                            weatherCondition: 'clear',
                                            startLat: _currentPosition!.latitude,
                                            startLng: _currentPosition!.longitude,
                                            endLat: result.latitude,
                                            endLng: result.longitude,
                                          ),
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Route computed: ${routeResult.path.join(' -> ')}, ETA: ${routeResult.etaMinutes.toStringAsFixed(1)} min'),
                                            action: SnackBarAction(
                                              label: 'View Route',
                                              onPressed: () {
                                                Navigator.pushNamed(context, '/map');
                                              },
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error computing route: $e')),
                                        );
                                      }
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Current location not available')),
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: 3, // Delivery tab selected
          onDestinationSelected: (index) {
            switch (index) {
              case 0:
                Navigator.pushNamed(context, '/map');
                break;
              case 1:
                Navigator.pushNamed(context, '/prediction');
                break;
              case 2:
                Navigator.pushNamed(context, '/fleet');
                break;
              case 3:
                // Already on delivery screen
                break;
              default:
            }
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Map'),
            NavigationDestination(icon: Icon(Icons.show_chart_outlined), label: 'Predict'),
            NavigationDestination(icon: Icon(Icons.local_shipping_outlined), label: 'Fleet'),
            NavigationDestination(icon: Icon(Icons.search_outlined), label: 'Delivery'),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
