import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/gradient_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/primary_button.dart';
import '../services/route_provider.dart';
import '../services/api_service.dart';
import '../models/traffic_prediction.dart';

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  TrafficPrediction? _trafficPrediction;
  bool _loadingPrediction = false;

  @override
  void initState() {
    super.initState();
    _fetchTrafficPrediction();
  }

  Future<void> _fetchTrafficPrediction() async {
    setState(() => _loadingPrediction = true);
    try {
      final prediction = await ApiService.instance.getTrafficPrediction();
      setState(() => _trafficPrediction = prediction);
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _loadingPrediction = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Predictions')),
      drawer: const AppDrawer(),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      body: GradientBackground(
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
            final path = tuple.$3;
            final cost = tuple.$4;
            final eta = tuple.$5;
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Short-term Congestion Forecasts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      RepaintBoundary(
                        child: SizedBox(
                          height: 180,
                          child: _loadingPrediction
                              ? const Center(child: CircularProgressIndicator())
                              : _trafficPrediction != null
                                  ? _TrafficPredictionChart(predictions: _trafficPrediction!.predictions)
                                  : const _ForecastChart(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ETA & Route Recommendation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: loading
                            ? const LinearProgressIndicator(key: ValueKey('loading'))
                            : const SizedBox.shrink(key: ValueKey('idle')),
                      ),
                      if (error != null)
                        Text('Error: $error', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: (!loading && path.isNotEmpty)
                            ? Column(
                                key: const ValueKey('result'),
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: path.map((n) => Chip(label: Text(n))).toList(),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Total cost: ${cost.toStringAsFixed(2)}'),
                                  Text('ETA: ${eta.toStringAsFixed(1)} min'),
                                ],
                              )
                            : const SizedBox.shrink(key: ValueKey('noresult')),
                      ),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        label: loading ? 'Computing...' : 'Compute Sample Route',
                        icon: Icons.auto_awesome,
                        onPressed: loading
                            ? null
                            : () {
                                context.read<RouteProvider>().fetchRoute(
                                  edges: const [
                                    {'source': 'A', 'target': 'B', 'weight': 1.0},
                                    {'source': 'B', 'target': 'C', 'weight': 2.0},
                                    {'source': 'A', 'target': 'C', 'weight': 4.0},
                                    {'source': 'C', 'target': 'D', 'weight': 1.0},
                                    {'source': 'B', 'target': 'D', 'weight': 5.0},
                                  ],
                                  start: 'A',
                                  end: 'D',
                                  heuristic: const {'A': 3, 'B': 2, 'C': 1, 'D': 0},
                                );
                              },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const GlassCard(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Weather-aware Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      SizedBox(height: 12),
                      _ChartPlaceholder(height: 160, label: 'Weather impact on traffic'),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TrafficPredictionChart extends StatelessWidget {
  final List<CongestionPrediction> predictions;

  const _TrafficPredictionChart({required this.predictions});

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.outlineVariant;
    final primary = Theme.of(context).colorScheme.primary;
    final spots = predictions.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.level)).toList();
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: true, border: Border.all(color: borderColor)),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            spots: spots,
          ),
        ],
      ),
    );
  }
}

class _ForecastChart extends StatelessWidget {
  const _ForecastChart();

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.outlineVariant;
    final primary = Theme.of(context).colorScheme.primary;
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: true, border: Border.all(color: borderColor)),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            spots: const [
              FlSpot(0, 2), FlSpot(1, 2.5), FlSpot(2, 2.2), FlSpot(3, 3.2), FlSpot(4, 2.8), FlSpot(5, 3.6)
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartPlaceholder extends StatelessWidget {
  final double height;
  final String label;
  const _ChartPlaceholder({required this.height, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Text(label),
    );
  }
}
