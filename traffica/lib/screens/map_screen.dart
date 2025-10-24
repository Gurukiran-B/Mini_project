import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/gradient_background.dart';
import '../widgets/map_widget.dart';
import '../widgets/primary_button.dart';
import '../services/route_provider.dart';
import '../models/optimal_route_input.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await LocationService.getCurrentLocation();
      setState(() {
        _currentPosition = position;
        _startController.text = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Traffic', icon: Icon(Icons.traffic_rounded)),
            Tab(text: 'Weather', icon: Icon(Icons.cloud_outlined)),
            Tab(text: 'Routes', icon: Icon(Icons.alt_route_rounded)),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      body: GradientBackground(
        child: TabBarView(
          controller: _tabController,
          children: [
            const MapWidget(), // Traffic layer with weather overlay
            const _MapPlaceholder(label: 'Weather layer on map'),
            RepaintBoundary(
              child: Selector<RouteProvider, (bool, Object?, List<String>, double, double)>(
              selector: (context, p) => (
                p.loading,
                p.error,
                p.result?.path ?? const <String>[],
                p.result?.totalCost ?? 0.0,
                p.result?.etaMinutes ?? 0.0,
              ),
              builder: (context, tuple, _) {
                final loading = tuple.$1;
                final error = tuple.$2;
                final nodes = tuple.$3;
                final cost = tuple.$4;
                final eta = tuple.$5;
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text('Start Location', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextField(
                      controller: _startController,
                      decoration: InputDecoration(
                        hintText: 'Enter start location or use current',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.my_location),
                          onPressed: _getCurrentLocation,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Destination Location', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextField(
                      controller: _endController,
                      decoration: const InputDecoration(
                        hintText: 'Enter destination location',
                      ),
                    ),
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: loading
                          ? const LinearProgressIndicator(key: ValueKey('loading'))
                          : const SizedBox.shrink(key: ValueKey('idle')),
                    ),
                    const SizedBox(height: 12),
                    if (nodes.isNotEmpty)
                      Text('Route: ${nodes.join(' -> ')}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            label: loading ? 'Computing...' : 'Compute Optimal Route',
                            icon: Icons.alt_route_rounded,
                            onPressed: loading
                                ? null
                                : () async {
                                    if (_startController.text.isEmpty || _endController.text.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please enter start and destination locations')),
                                      );
                                      return;
                                    }
                                    try {
                                      // Parse coordinates if provided
                                      double? startLat, startLng, endLat, endLng;
                                      final startParts = _startController.text.split(',');
                                      final endParts = _endController.text.split(',');
                                      if (startParts.length == 2) {
                                        startLat = double.tryParse(startParts[0].trim());
                                        startLng = double.tryParse(startParts[1].trim());
                                      }
                                      if (endParts.length == 2) {
                                        endLat = double.tryParse(endParts[0].trim());
                                        endLng = double.tryParse(endParts[1].trim());
                                      }

                                      final result = await ApiService.instance.getOptimalRoute(
                                        OptimalRouteInput(
                                          fromLocation: _startController.text,
                                          toLocation: _endController.text,
                                          time: DateTime.now(),
                                          weatherCondition: 'clear',
                                          startLat: startLat,
                                          startLng: startLng,
                                          endLat: endLat,
                                          endLng: endLng,
                                        ),
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Route: ${result.path.join(' -> ')}, ETA: ${result.etaMinutes.toStringAsFixed(1)} min')),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: $e')),
                                      );
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                    if (nodes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('ETA: ${eta.toStringAsFixed(1)} min'),
                      Text('Cost: ${cost.toStringAsFixed(2)}'),
                    ],
                    if (error != null)
                      Text('Error: $error', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                );
              },
            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  final String label;
  const _MapPlaceholder({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 220,
        width: 320,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Text(label),
      ),
    );
  }
}
