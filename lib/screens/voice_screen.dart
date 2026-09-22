import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:math';
import 'package:path_provider/path_provider.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  final AudioRecorder _recorder = AudioRecorder();

  int _currentTest = 0;
  int _countdown = 0;
  bool _recording = false;
  bool _processing = false;
  Timer? _timer;
  Timer? _amplitudeTimer;

  // Amplitude samples per test
  List<double> _breathingAmplitudes = [];
  List<double> _voiceAmplitudes = [];
  List<double> _sustainAmplitudes = [];

  // Results
  String _breathingRate = '';
  String _breathingStatus = '';
  String _tremorLevel = '';
  String _tremorStatus = '';
  String _stabilityScore = '';
  String _stabilityStatus = '';

  final List<Map<String, String>> _tests = [
    {
      'title': 'Breathing Test',
      'instruction': 'Breathe normally.\nDo not speak.',
      'duration': '15',
    },
    {
      'title': 'Voice Test',
      'instruction':
          'Read this aloud:\n\n"The quick brown fox jumps over the lazy dog near the river bank."',
      'duration': '10',
    },
    {
      'title': 'Sustain Test',
      'instruction': 'Say "aaah" continuously\nat a comfortable pitch.',
      'duration': '10',
    },
  ];

  Future<void> _startTest() async {
    await Permission.microphone.request();

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_test_$_currentTest.m4a';
    final duration = int.parse(_tests[_currentTest - 1]['duration']!);

    // Clear amplitude buffer
    if (_currentTest == 1) _breathingAmplitudes = [];
    if (_currentTest == 2) _voiceAmplitudes = [];
    if (_currentTest == 3) _sustainAmplitudes = [];

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );

    setState(() {
      _recording = true;
      _countdown = duration;
    });

    // Sample amplitude every 100ms
    _amplitudeTimer =
        Timer.periodic(const Duration(milliseconds: 100), (_) async {
      final amp = await _recorder.getAmplitude();
      final value = amp.current.isFinite ? amp.current + 160 : 0;
      if (_currentTest == 1) _breathingAmplitudes.add(value.toDouble());
      if (_currentTest == 2) _voiceAmplitudes.add(value.toDouble());
      if (_currentTest == 3) _sustainAmplitudes.add(value.toDouble());
    });

    // Countdown
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _countdown--);
      if (_countdown <= 0) {
        timer.cancel();
        _stopTest();
      }
    });
  }

  Future<void> _stopTest() async {
    _amplitudeTimer?.cancel();
    await _recorder.stop();

    setState(() {
      _recording = false;
      _processing = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));
    _analyzeCurrentTest();

    setState(() {
      _processing = false;
      if (_currentTest < 3) {
        _currentTest++;
      } else {
        _currentTest = 4;
      }
    });

    if (_currentTest < 4) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _startTest();
      });
    }
  }

  void _analyzeCurrentTest() {
    if (_currentTest == 1) _analyzeBreathing();
    if (_currentTest == 2) _analyzeVoice();
    if (_currentTest == 3) _analyzeSustain();
  }

  void _analyzeBreathing() {
    final signal = _breathingAmplitudes;
    if (signal.isEmpty) {
      _breathingRate = 'Unable to detect';
      _breathingStatus = 'No signal captured';
      return;
    }

    // Smooth signal
    final smoothed = _movingAverage(signal, windowSize: 10);

    // Find breathing peaks (slow signal changes)
    final peaks = _findPeaks(smoothed, minDistance: 15);

    final durationMin = signal.length / 10.0 / 60.0;
    final rr = peaks.length > 1 ? peaks.length / durationMin : 0;

    if (rr >= 8 && rr <= 25) {
      _breathingRate = '${rr.toStringAsFixed(0)} breaths/min';
      if (rr >= 12 && rr <= 20) {
        _breathingStatus = 'Normal range';
      } else if (rr < 12) {
        _breathingStatus = 'Slow breathing';
      } else {
        _breathingStatus = 'Fast breathing';
      }
    } else {
      _breathingRate = 'Irregular signal';
      _breathingStatus = 'Keep still and breathe normally';
    }
  }

  void _analyzeVoice() {
    final signal = _voiceAmplitudes;
    if (signal.isEmpty) {
      _tremorLevel = 'Unable to detect';
      _tremorStatus = 'No signal captured';
      return;
    }

    // Only analyze parts where voice is active (amplitude above threshold)
    final mean = signal.reduce((a, b) => a + b) / signal.length;
    final activeSegments =
        signal.where((v) => v > mean * 0.5).toList();

    if (activeSegments.length < 10) {
      _tremorLevel = 'No voice detected';
      _tremorStatus = 'Please read the sentence aloud';
      return;
    }

    // Tremor = variation in active voice segments
    final activeMean =
        activeSegments.reduce((a, b) => a + b) / activeSegments.length;
    final variance = activeSegments
            .map((v) => pow(v - activeMean, 2))
            .reduce((a, b) => a + b) /
        activeSegments.length;
    final stdDev = sqrt(variance);
    final cv = stdDev / activeMean; // coefficient of variation

    if (cv < 0.15) {
      _tremorLevel = 'Low';
      _tremorStatus = 'No significant tremor detected';
    } else if (cv < 0.30) {
      _tremorLevel = 'Mild';
      _tremorStatus = 'Minor voice variation — normal';
    } else {
      _tremorLevel = 'Elevated';
      _tremorStatus = 'Noticeable variation detected';
    }
  }

  void _analyzeSustain() {
    final signal = _sustainAmplitudes;
    if (signal.isEmpty) {
      _stabilityScore = 'Unable to detect';
      _stabilityStatus = 'No signal captured';
      return;
    }

    final mean = signal.reduce((a, b) => a + b) / signal.length;
    final activeSegments = signal.where((v) => v > mean * 0.3).toList();

    if (activeSegments.length < 20) {
      _stabilityScore = 'Insufficient signal';
      _stabilityStatus = 'Sustain the "aaah" sound longer';
      return;
    }

    final activeMean =
        activeSegments.reduce((a, b) => a + b) / activeSegments.length;
    final variance = activeSegments
            .map((v) => pow(v - activeMean, 2))
            .reduce((a, b) => a + b) /
        activeSegments.length;
    final stdDev = sqrt(variance);
    final stability = (1 - (stdDev / activeMean)).clamp(0.0, 1.0);
    final stabilityPct = (stability * 100).round();

    _stabilityScore = '$stabilityPct%';
    if (stabilityPct >= 75) {
      _stabilityStatus = 'Good voice stability';
    } else if (stabilityPct >= 50) {
      _stabilityStatus = 'Moderate stability';
    } else {
      _stabilityStatus = 'Low stability — may indicate fatigue';
    }
  }

  List<double> _movingAverage(List<double> signal, {int windowSize = 5}) {
    List<double> result = List.filled(signal.length, 0);
    for (int i = 0; i < signal.length; i++) {
      int start = (i - windowSize ~/ 2).clamp(0, signal.length - 1);
      int end = (i + windowSize ~/ 2).clamp(0, signal.length - 1);
      double sum = 0;
      for (int j = start; j <= end; j++) {
        sum += signal[j];
      }
      result[i] = sum / (end - start + 1);
    }
    return result;
  }

  List<int> _findPeaks(List<double> signal, {int minDistance = 10}) {
    List<int> peaks = [];
    for (int i = 1; i < signal.length - 1; i++) {
      if (signal[i] > signal[i - 1] && signal[i] > signal[i + 1]) {
        if (peaks.isEmpty || i - peaks.last >= minDistance) {
          peaks.add(i);
        }
      }
    }
    return peaks;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _amplitudeTimer?.cancel();
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
          style: const TextStyle(color: Color(0xFF6B6661), fontSize: 14),
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
              border:
                  Border.all(color: const Color(0xFF8E8882), width: 2),
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
                  style:
                      TextStyle(color: Color(0xFFA8A29E), fontSize: 16)),
            ],
          ),
        ] else
          const CircularProgressIndicator(color: Color(0xFFE8E4DE)),
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
            title: 'Breathing Rate',
            value: _breathingRate,
            subtitle: _breathingStatus,
          ),
          const SizedBox(height: 12),
          _ResultBlock(
            title: 'Voice Tremor',
            value: _tremorLevel,
            subtitle: _tremorStatus,
          ),
          const SizedBox(height: 12),
          _ResultBlock(
            title: 'Voice Stability',
            value: _stabilityScore,
            subtitle: _stabilityStatus,
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
          const SizedBox(height: 24),
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
  final String value;
  final String subtitle;

  const _ResultBlock({
    required this.title,
    required this.value,
    required this.subtitle,
  });

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
          Text(title,
              style: const TextStyle(
                  color: Color(0xFFA8A29E), fontSize: 13)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                color: Color(0xFFE8E4DE),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              )),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(
                  color: Color(0xFF6B6661), fontSize: 13)),
        ],
      ),
    );
  }
}