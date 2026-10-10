import 'package:e_venues/authentication/register_screen.dart';
import 'package:e_venues/theme/app_theme.dart';
import 'package:e_venues/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
import 'package:e_venues/services/auth_token.dart';
import 'package:e_venues/ui/ui.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

void main() {
  // Session expiry: any authed 401 logs out and drops back to login.
  bool navigating = false;
  AuthTokenStore.onAuthFailure = () async {
    if (navigating) return;
    navigating = true;
    try {
      final ctx = _navigatorKey.currentContext;
      if (ctx != null) {
        try {
          await ctx.read<AuthProvider>().logout();
        } catch (_) {}
      }
      _navigatorKey.currentState
          ?.pushNamedAndRemoveUntil('/login', (_) => false);
    } finally {
      navigating = false;
    }
  };
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..restore()),
        ChangeNotifierProvider(create: (_) => VenueProvider()),
        ChangeNotifierProvider(create: (_) => SavedProvider()..restore()),
        ChangeNotifierProxyProvider<AuthProvider, BookingProvider>(
          create: (_) => BookingProvider()..restore(),
          // Booking storage follows the session: server copy when
          // logged in, local copy when logged out.
          update: (_, auth, prev) => prev!..syncAuth(auth.isLoggedIn),
        ),
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
      title: 'Haven',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
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
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  int _replayKey = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer(Duration(milliseconds: 3800), () async {
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token') ??
          prefs.getString('auth_token');
      if (!mounted) return;
      // Onboarding shows after every logged-out launch; the carousel
      // itself forwards to login via Get started / Skip / Log in.
      if (token != null && token.isNotEmpty) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static const _tagline = [
    ('Find', _TagStyle.normal),
    ('your', _TagStyle.normal),
    ('place', _TagStyle.accent),
    ('for', _TagStyle.normal),
    ('every', _TagStyle.normal),
    ('moment.', _TagStyle.strong),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -96,
              left: -80,
              child: _blob(288, AppTokens.primaryTint
                  .withValues(alpha: 0.3)),
            ),
            Positioned(
              top: 220,
              right: -96,
              child:
                  _blob(320, AppTokens.primary.withValues(alpha: 0.1)),
            ),
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: Center(
                child: _blob(200,
                    AppTokens.secondary.withValues(alpha: 0.12)),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTokens.surface,
                          borderRadius:
                              BorderRadius.circular(16),
                          border: Border.all(
                              color: AppTokens.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppTokens.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppTokens.primary
                                    .withValues(alpha: 0.4),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('DAR DISCOVERY',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                    color:
                                        AppTokens.inkSecondary)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _replayKey++),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                AppTokens.surfaceSecondary,
                            borderRadius:
                                BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(AppIcons.refresh,
                                  size: 16,
                                  color:
                                      AppTokens.inkSecondary),
                              SizedBox(width: 4),
                              // Text('Replay',
                              //     style: TextStyle(
                              //         fontSize: 11,
                              //         color: AppTokens
                              //             .inkSecondary)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: KeyedSubtree(
                      key: ValueKey(_replayKey),
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              _blob(
                                  150,
                                  AppTokens.primary
                                      .withValues(alpha: 0.2)),
                              _LogoEntrance(
                                child: Container(
                                  width: 112,
                                  height: 112,
                                  decoration: BoxDecoration(
                                    color: AppTokens.surface,
                                    borderRadius:
                                        BorderRadius.circular(
                                            28),
                                    border: Border.all(
                                        color: AppTokens
                                            .border),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(
                                            0x24FF5A5F),
                                        blurRadius: 32,
                                        offset: Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(
                                            28),
                                    // landingpage.png is the full
                                    // HAVEN lockup; this window
                                    // frames the H mark only
                                    // (top 12%-60% band).
                                    child: const Stack(
                                      children: [
                                        Positioned(
                                          top: -28,
                                          left: -119,
                                          width: 350,
                                          child: Image(
                                            image: AssetImage(
                                                'assets/images/landingpage.png'),
                                            width: 350,
                                            fit: BoxFit.fitWidth,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          const _DelayedFade(
                            delayMs: 350,
                            child: Text('HAVEN',
                                style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                    color: AppTokens.ink)),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 6,
                            children: [
                              for (var i = 0;
                                  i < _tagline.length;
                                  i++)
                                _DelayedFade(
                                  delayMs: 750 + i * 130,
                                  dy: 10,
                                  child: Text(
                                      _tagline[i].$1,
                                      style: _tagStyle(
                                          _tagline[i].$2)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _DelayedFade(
                            delayMs: 1000,
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: const [
                                _FeaturePill(
                                    icon:
                                        AppIcons.celebration,
                                    label: 'Weddings',
                                    color: AppTokens.primary),
                                SizedBox(width: 8),
                                _FeaturePill(
                                    icon: AppIcons.work,
                                    label: 'Corporate',
                                    color:
                                        AppTokens.secondary),
                                SizedBox(width: 8),
                                _FeaturePill(
                                    icon: AppIcons.beach,
                                    label: 'Coastal',
                                    color: AppTokens.success),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _DelayedFade(
                    delayMs: 1150,
                    dy: 8,
                    child: Column(
                      children: [
                        SizedBox(
                          width: 176,
                          child: LinearProgressIndicator(
                            minHeight: 3,
                            backgroundColor:
                                AppTokens.border,
                            color: AppTokens.primary,
                            borderRadius:
                                BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                            'Dar es Salaam, Tanzania • v1.0',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color:
                                    AppTokens.inkSecondary)),
                        const SizedBox(height: 2),
                        const Text(
                            'Masaki • CBD • Oysterbay • Kigamboni',
                            style: TextStyle(
                                fontSize: 10,
                                color:
                                    AppTokens.inkTertiary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration:
          BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  static TextStyle _tagStyle(_TagStyle style) {
    switch (style) {
      case _TagStyle.accent:
        return const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTokens.primary);
      case _TagStyle.strong:
        return const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTokens.ink);
      case _TagStyle.normal:
        return const TextStyle(
            fontSize: 14, color: AppTokens.inkSecondary);
    }
  }
}

enum _TagStyle { normal, accent, strong }

/// Logo entrance: fade + 0.88 scale with overshoot (spec keyframes).
class _LogoEntrance extends StatelessWidget {
  final Widget child;
  const _LogoEntrance({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1100),
      curve: const Interval(0, 0.8, curve: Curves.easeOutBack),
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.88 + 0.12 * t,
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Delayed fade-and-rise using an Interval curve (spec stagger).
class _DelayedFade extends StatelessWidget {
  final int delayMs;
  final double dy;
  final Widget child;
  const _DelayedFade({
    required this.delayMs,
    this.dy = 14,
    required this.child,
  });

  static const _totalMs = 1500;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: _totalMs),
      curve: Interval(delayMs / _totalMs, 1.0, curve: Curves.easeOut),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, dy * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _FeaturePill(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTokens.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTokens.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTokens.inkSecondary)),
        ],
      ),
    );
  }
}

