import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  
  int _currentTest = 0; // 0=intro, 1=breathing, 2=voice, 3=sustain, 4=results
  int _countdown = 0;
  bool _recording = false;
  bool _processing = false;
  Timer? _timer;

  // Results
  String _breathingResult = '';
  String _voiceResult = '';
  String _sustainResult = '';

  final List<Map<String, String>> _tests = [
    {
      'title': 'Breathing Test',
      'instruction': 'Breathe normally.\nDo not speak.',
      'duration': '15',
      'icon': 'air',
    },
    {
      'title': 'Voice Test',
      'instruction': 'Read this aloud:\n\n"The quick brown fox jumps over the lazy dog near the river bank."',
      'duration': '10',
      'icon': 'mic',
    },
    {
      'title': 'Sustain Test',
      'instruction': 'Say "aaah" continuously\nat a comfortable pitch.',
      'duration': '10',
      'icon': 'record_voice_over',
    },
  ];

  Future<void> _startTest() async {
    await Permission.microphone.request();
    
    final test = _tests[_currentTest - 1];
    final duration = int.parse(test['duration']!);
    
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_test_$_currentTest.m4a';
    
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    
    setState(() {
      _recording = true;
      _countdown = duration;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _countdown--);
      if (_countdown <= 0) {
        timer.cancel();
        _stopTest();
      }
    });
  }

  Future<void> _stopTest() async {
    await _recorder.stop();
    setState(() {
      _recording = false;
      _processing = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    // Simulate analysis results
    if (_currentTest == 1) {
      _breathingResult = 'Breathing pattern: Regular\nEstimated rate: 14-16 breaths/min';
    } else if (_currentTest == 2) {
      _voiceResult = 'Voice tremor: Not detected\nSpeech rate: Normal';
    } else if (_currentTest == 3) {
      _sustainResult = 'Voice stability: Good\nBreathiness: Low';
    }

        setState(() {
        _processing = false;
        if (_currentTest < 3) {
            _currentTest++;
        } else {
            _currentTest = 4;
        }
        });

        // Auto start next test after short delay
        if (_currentTest < 4) {
        Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) _startTest();
        });
        }
        }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1917),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1917),
        foregroundColor: const Color(0xFFE8E4DE),
        title: const Text('Voice & Breathing Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _currentTest == 0
            ? _buildIntro()
            : _currentTest == 4
                ? _buildResults()
                : _buildTest(),
      ),
    );
  }

  Widget _buildIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Voice & Breathing\nAnalysis',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE8E4DE),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 24),
        _InfoCard(
            icon: Icons.air,
            title: 'Breathing Test',
            subtitle: '15 seconds — breathe normally'),
        const SizedBox(height: 12),
        _InfoCard(
            icon: Icons.mic,
            title: 'Voice Test',
            subtitle: '10 seconds — read a sentence'),
        const SizedBox(height: 12),
        _InfoCard(
            icon: Icons.record_voice_over,
            title: 'Sustain Test',
            subtitle: '10 seconds — say "aaah"'),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              setState(() => _currentTest = 1);
              Future.delayed(
                  const Duration(milliseconds: 300), _startTest);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8E4DE),
              foregroundColor: const Color(0xFF1C1917),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Start Tests',
                style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildTest() {
    final test = _tests[_currentTest - 1];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Test $_currentTest of 3',
          style: const TextStyle(
              color: Color(0xFF6B6661), fontSize: 14),
        ),
        const SizedBox(height: 24),
        Text(
          test['title']!,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE8E4DE),
          ),
        ),
        const SizedBox(height: 32),
        if (_processing)
          const CircularProgressIndicator(color: Color(0xFFE8E4DE))
        else if (_recording) ...[
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF262320),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(
                  color: const Color(0xFF8E8882), width: 2),
            ),
            child: Center(
              child: Text(
                '$_countdown',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE8E4DE),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fiber_manual_record,
                  color: Color(0xFF9AA5B1), size: 12),
              SizedBox(width: 8),
              Text('Recording...',
                  style: TextStyle(
                      color: Color(0xFFA8A29E), fontSize: 16)),
            ],
          ),
        ] else ...[
          const CircularProgressIndicator(color: Color(0xFFE8E4DE)),
        ],
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF262320),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF34302D)),
          ),
          child: Text(
            test['instruction']!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFE8E4DE),
              fontSize: 16,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Voice Analysis Results',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE8E4DE),
            ),
          ),
          const SizedBox(height: 24),
          _ResultBlock(
              title: 'Breathing', content: _breathingResult),
          const SizedBox(height: 12),
          _ResultBlock(title: 'Voice', content: _voiceResult),
          const SizedBox(height: 12),
          _ResultBlock(
              title: 'Voice Stability', content: _sustainResult),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF262320),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF34302D)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline,
                    color: Color(0xFF9AA5B1), size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Full voice biomarker analysis coming in next update.',
                    style: TextStyle(
                        color: Color(0xFFA8A29E), fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8E4DE),
                foregroundColor: const Color(0xFF1C1917),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Done',
                  style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF262320),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF34302D)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFE8E4DE), size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                    color: Color(0xFFE8E4DE),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  )),
              Text(subtitle,
                  style: const TextStyle(
                      color: Color(0xFFA8A29E), fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultBlock extends StatelessWidget {
  final String title;
  final String content;

  const _ResultBlock({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF262320),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF34302D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFA8A29E),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: Color(0xFFE8E4DE),
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
