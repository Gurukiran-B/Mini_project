import 'dart:async';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/config.dart';
import '../models/weather_data.dart';
import '../models/traffic_prediction.dart';
import '../models/fleet_status.dart';
import '../models/optimal_route_input.dart';
import '../models/route_result.dart';
import '../models/delivery_search_result.dart';

class ApiService {
  ApiService._internal()
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 10),
          ),
        ) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['Accept'] = 'application/json';
        return handler.next(options);
      },
      onError: (e, handler) {
        return handler.next(e);
      },
    ));
  }

  static final ApiService instance = ApiService._internal();
  final Dio _dio;

  Future<Map<String, dynamic>> computeRoute({
    required List<Map<String, dynamic>> edges,
    required String start,
    required String end,
    Map<String, double>? heuristic,
  }) async {
    final payload = {
      'edges': edges,
      'start': start,
      'end': end,
      if (heuristic != null) 'heuristic': heuristic,
    };

    int attempts = 0;
    while (true) {
      attempts++;
      try {
        final res = await _dio.post('/route', data: payload);
        return res.data as Map<String, dynamic>;
      } on DioException catch (e) {
        if (attempts >= 3 || (e.type != DioExceptionType.connectionTimeout && e.type != DioExceptionType.receiveTimeout)) {
          rethrow;
        }
        await Future.delayed(Duration(milliseconds: 300 * attempts));
      }
    }
  }

  Future<RouteResult> getOptimalRoute(OptimalRouteInput input) async {
    final res = await _dio.post('/optimal_route', data: input.toJson());
    return RouteResult.fromJson(res.data);
  }

  Future<TrafficPrediction> getTrafficPrediction({String location = 'downtown'}) async {
    final res = await _dio.get('/predict_traffic', queryParameters: {'location': location});
    return TrafficPrediction.fromJson(res.data);
  }

  Future<FleetStatus> getFleetStatus() async {
    final res = await _dio.get('/fleet_status');
    return FleetStatus.fromJson(res.data);
  }

  Future<WeatherData> getWeather({String location = 'downtown'}) async {
    final res = await _dio.get('/weather', queryParameters: {'location': location});
    return WeatherData.fromJson(res.data);
  }

  Future<List<DeliverySearchResult>> searchDeliveryAddresses({String query = ''}) async {
    final res = await _dio.get('/search_address', queryParameters: {'query': query});
    final List<dynamic> data = res.data;
    return data.map((item) => DeliverySearchResult.fromJson(item)).toList();
  }
}


