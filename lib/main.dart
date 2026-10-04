import 'package:e_venues/authentication/register_screen.dart';
import 'package:e_venues/theme/app_theme.dart';
import 'package:e_venues/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_venues/onboarding_screen.dart';
import 'package:e_venues/authentication/login_screen.dart';
import 'package:e_venues/home/home_screen.dart';
import 'package:e_venues/screens/saved_screen.dart';
import 'package:e_venues/screens/bookings_screen.dart';
import 'package:e_venues/profile_screen.dart';
import 'package:e_venues/providers/auth_provider.dart';
import 'package:e_venues/providers/venue_provider.dart';
import 'package:e_venues/providers/saved_provider.dart';
import 'package:e_venues/providers/booking_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..restore()),
        ChangeNotifierProvider(create: (_) => VenueProvider()),
        ChangeNotifierProvider(create: (_) => SavedProvider()..restore()),
        ChangeNotifierProvider(create: (_) => BookingProvider()..restore()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Venues TZ',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: SplashScreen(),
      routes: {
        '/onboarding': (_) => OnboardingScreen(),
        '/login': (_) => LoginScreen(),
        '/home': (_) => HomeScreen(),
        '/saved': (_) => const SavedScreen(),
        '/bookings': (_) => const BookingsScreen(),
        '/profile': (_) => ProfileScreen(),
        '/register': (_) => RegisterPage(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctr;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _ctr = AnimationController(vsync: this, duration: Duration(milliseconds: 1400));
    _ctr.repeat(reverse: true);
    _timer = Timer(Duration(milliseconds: 1800), () async {
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool('onboarding_seen') ?? false;
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(seen ? '/login' : '/onboarding');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ScaleTransition(
              scale: Tween(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _ctr, curve: Curves.easeOut)),
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppTokens.coral,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(Icons.place_rounded, size: 56, color: Colors.white),
              ),
            ),
            SizedBox(height: 20),
            Text('E-Venues', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTokens.coral)),
            SizedBox(height: 6),
            Text('Find the perfect spot', style: TextStyle(fontSize: 14, color: AppTokens.inkSecondary)),
            SizedBox(height: 24),
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                backgroundColor: AppTokens.border,
                color: AppTokens.coral,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

