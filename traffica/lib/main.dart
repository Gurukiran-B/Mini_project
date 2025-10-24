import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/map_screen.dart';
import 'screens/prediction_screen.dart';
import 'screens/fleet_screen.dart';
import 'screens/delivery_search_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notifications_screen.dart';
import 'theme/app_theme.dart';
import 'services/route_provider.dart';

void main() => runApp(TrafficaApp());

class TrafficaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RouteProvider()),
      ],
      child: AdaptiveTheme(
        light: AppTheme.light(),
        dark: AppTheme.light().copyWith(brightness: Brightness.dark),
        initial: AdaptiveThemeMode.light,
        builder: (theme, darkTheme) => MaterialApp(
          title: 'Traffica',
          debugShowCheckedModeBanner: false,
          theme: theme,
          darkTheme: darkTheme,
          initialRoute: '/splash',
          routes: {
            '/splash': (context) => SplashScreen(),
            '/login': (context) => LoginScreen(),
            '/dashboard': (context) => DashboardScreen(),
            '/map': (context) => MapScreen(),
            '/prediction': (context) => PredictionScreen(),
            '/fleet': (context) => FleetScreen(),
            '/delivery_search': (context) => DeliverySearchScreen(),
            '/profile': (context) => ProfileScreen(),
            '/notifications': (context) => NotificationsScreen(),
          },
        ),
      ),
    );
  }
}
