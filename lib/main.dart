import 'package:flutter/material.dart';
import 'screens/ppg_screen.dart';
import 'screens/reaction_time_screen.dart';
import 'screens/voice_screen.dart';

void main() {
  runApp(const VitalScanApp());
}

class VitalScanApp extends StatelessWidget {
  const VitalScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VitalScan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1C1917),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE8E4DE),
          surface: Color(0xFF262320),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE8E4DE),
            foregroundColor: const Color(0xFF1C1917),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                'VitalScan',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE8E4DE),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Smartphone health screening',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFFA8A29E),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF262320),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF34302D)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How it works',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE8E4DE),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '1. Place finger firmly on rear camera\n'
                      '2. Cover the flash completely\n'
                      '3. Keep still for 30 seconds\n'
                      '4. See your heart rate and breathing rate',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFA8A29E),
                        height: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PPGScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Start Scan',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ReactionTimeScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color.fromARGB(255, 246, 243, 243),
                    side: const BorderSide(color: Color.fromARGB(255, 241, 240, 240)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Reaction Time Test',
                      style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VoiceScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE8E4DE),
                    side: const BorderSide(color: Color(0xFF34302D)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Voice & Breathing Test',
                      style: TextStyle(fontSize: 16)),
                ),
              ),
            const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Not a medical device — for screening only',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color.fromARGB(255, 236, 232, 232),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}