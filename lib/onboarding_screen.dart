import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme/tokens.dart';

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
      'title': "Find venues you'll love",
      'subtitle': 'Curated halls across Dar es Salaam, searched in seconds.',
      'image': 'assets/images/room-used-official-event.jpg'
    },
    {
      'title': 'See it on the map',
      'subtitle': 'Transparent pricing and location at a glance.',
      'image': 'assets/images/conference-room.jpg'
    },
    {
      'title': 'Book with confidence',
      'subtitle': 'Pick dates, see the total, done. No surprises.',
      'image': 'assets/images/cozy-cafeteria.jpg'
    },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pc,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final p = pages[i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppTokens.radiusCard),
                            child: Image.asset(
                              p['image']!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(32, 28, 32, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p['title']!,
                                style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: AppTokens.ink)),
                            const SizedBox(height: 8),
                            Text(p['subtitle']!,
                                style: const TextStyle(
                                    color: AppTokens.inkSecondary,
                                    fontSize: 15)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Row(
                children: [
                  Row(
                    children: List.generate(
                        pages.length,
                        (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(right: 6),
                              width: _index == i ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _index == i
                                    ? AppTokens.ink
                                    : AppTokens.border,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            )),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _finish,
                    style: TextButton.styleFrom(
                        foregroundColor: AppTokens.inkSecondary,
                        textStyle: const TextStyle(
                            decoration: TextDecoration.none)),
                    child: const Text('Skip'),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 140,
                    child: ElevatedButton(
                        onPressed: () {
                          if (_index < pages.length - 1) {
                            _pc.nextPage(
                                duration:
                                    const Duration(milliseconds: 350),
                                curve: Curves.easeOut);
                          } else {
                            _finish();
                          }
                        },
                        child: Text(_index < pages.length - 1
                            ? 'Next'
                            : 'Get started')),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
