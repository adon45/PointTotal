import 'package:flutter/material.dart';

import 'home_screen.dart';

class LaunchScreen extends StatelessWidget {
  const LaunchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),
                  Image.asset(
                    'assets/images/point_tracker_icon.png',
                    width: 144,
                    height: 144,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.photo_camera_outlined,
                      size: 120,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Point Tracker',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text(
                        'Continue',
                        style: TextStyle(fontSize: 18),
                      ),
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => const HomeScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Created by Austin Donovan',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
