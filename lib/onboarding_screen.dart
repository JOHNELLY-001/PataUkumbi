import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme/tokens.dart';
import 'ui/ui.dart';

/// Coastal onboarding carousel (UI_design.txt). Shows after splash
/// whenever there is no logged-in session.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pc = PageController();
  int _index = 0;

  static const List<Map<String, String>> pages = [
    {
      'title': 'Find the Perfect Spot',
      'subtitle':
          'Discover premier ballrooms, executive boardrooms, and celebration venues across Dar es Salaam.',
      'image': 'assets/images/room-used-official-event.webp',
      'badge': 'Masaki • Executive Boardroom',
    },
    {
      'title': 'See It on the Map',
      'subtitle':
          'Explore venues with live transparent pricing, capacity checks, and neighborhood hotspots from Masaki to Posta.',
      'image': 'assets/images/conference-room.webp',
      'badge': 'Posta CBD • Live Map Rate',
    },
    {
      'title': 'Book with Confidence',
      'subtitle':
          'Direct reservations, hassle-free event permits, and secure local payments with M-Pesa verification.',
      'image': 'assets/images/cozy-cafeteria.webp',
      'badge': 'Oysterbay • Verified Host',
    },
  ];

  static const List<IconData> _badgeIcons = [
    AppIcons.building,
    AppIcons.map,
    AppIcons.verified,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final p in pages) {
        precacheImage(AssetImage(p['image']!), context);
      }
    });
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _goTo(int i) {
    _pc.animateToPage(i,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == pages.length - 1;
    return Scaffold(
      backgroundColor: AppTokens.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                children: [
                  ClipOval(
                    child: Image.asset(
                      'assets/images/haven.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Haven',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTokens.ink)),
                      Text('Dar es Salaam',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppTokens.inkSecondary)),
                    ],
                  ),
                  const Spacer(),
                  Visibility(
                    visible: !last,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: TextButton(
                      onPressed: _finish,
                      style: TextButton.styleFrom(
                          foregroundColor:
                              AppTokens.inkSecondary,
                          textStyle: const TextStyle(
                              decoration:
                                  TextDecoration.none)),
                      child: const Text('Skip'),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              flex: 5,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20),
                child: PageView.builder(
                  controller: _pc,
                  itemCount: pages.length,
                  onPageChanged: (i) =>
                      setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final p = pages[i];
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppTokens.border),
                        boxShadow: AppTokens.shadowCard,
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(20),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              p['image']!,
                              fit: BoxFit.cover,
                            ),
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin:
                                      Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Color(0x66000000)
                                  ],
                                  stops: [0.6, 1.0],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 12,
                              left: 12,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppTokens.surface
                                      .withValues(alpha: 0.9),
                                  borderRadius:
                                      BorderRadius.circular(
                                          16),
                                ),
                                child: Row(
                                  mainAxisSize:
                                      MainAxisSize.min,
                                  children: [
                                    Icon(_badgeIcons[i],
                                        size: 14,
                                        color:
                                            AppTokens.primary),
                                    const SizedBox(width: 4),
                                    Text(p['badge']!,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight:
                                                FontWeight.w600,
                                            color:
                                                AppTokens.ink)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                        pages.length,
                        (i) => GestureDetector(
                              onTap: () => _goTo(i),
                              behavior:
                                  HitTestBehavior.opaque,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 3),
                                child: AnimatedContainer(
                                  duration: const Duration(
                                      milliseconds: 300),
                                  width:
                                      _index == i ? 24 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _index == i
                                        ? AppTokens.primary
                                        : AppTokens.surfaceDim,
                                    borderRadius:
                                        BorderRadius.circular(
                                            8),
                                  ),
                                ),
                              ),
                            )),
                  ),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration:
                        const Duration(milliseconds: 200),
                    child: Text(
                      pages[_index]['title']!,
                      key: ValueKey('t$_index'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppTokens.ink),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration:
                        const Duration(milliseconds: 200),
                    child: Text(
                      pages[_index]['subtitle']!,
                      key: ValueKey('s$_index'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: AppTokens.inkSecondary),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: Column(
                children: [
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!last) {
                          _goTo(_index + 1);
                        } else {
                          _finish();
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(last
                              ? 'Get Started'
                              : 'Next'),
                          const SizedBox(width: 8),
                          Icon(
                              last
                                  ? AppIcons.celebration
                                  : AppIcons.forward,
                              size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                          'Already have an account? ',
                          style: TextStyle(
                              fontSize: 13,
                              color:
                                  AppTokens.inkSecondary)),
                      GestureDetector(
                        onTap: _finish,
                        child: const Text('Log in',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTokens.ink,
                                decoration: TextDecoration
                                    .underline)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
