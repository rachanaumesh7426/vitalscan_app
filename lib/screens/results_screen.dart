import 'package:flutter/material.dart';
import 'dart:math';

class ResultsScreen extends StatefulWidget {
  final List<double> redValues;
  final List<double> greenValues;

  const ResultsScreen({
    super.key,
    required this.redValues,
    required this.greenValues,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  double? _heartRate;
  double? _respiratoryRate;
  double? _hrv;
  String _stressLevel = '';
  int _signalQuality = 0;
  bool _processing = true;

  @override
  void initState() {
    super.initState();
    _analyzeSignal();
  }

  void _analyzeSignal() {
    try {
      final signal = widget.redValues;

      if (signal.length < 100) {
        setState(() {
          _processing = false;
        });
        return;
      }

      // Signal quality score
      final expected = 30 * 30; // 30 fps × 30 seconds
      _signalQuality = ((signal.length / expected) * 100).clamp(0, 100).toInt();

      // Normalize
      final mean = signal.reduce((a, b) => a + b) / signal.length;
      final normalized = signal.map((v) => v - mean).toList();

      // Filter
      final hrFiltered = _movingAverage(normalized, windowSize: 3);
      final rrFiltered = _movingAverage(normalized, windowSize: 15);

      // Peaks
      final hrPeaks = _findPeaks(hrFiltered, minDistance: 12);
      final rrPeaks = _findPeaks(rrFiltered, minDistance: 60);

      final durationSeconds = signal.length / 30.0;

      double hr = hrPeaks.length > 1
          ? (hrPeaks.length / durationSeconds) * 60
          : 0;
      double rr = rrPeaks.length > 1
          ? (rrPeaks.length / durationSeconds) * 60
          : 0;

      if (hr < 40 || hr > 200) hr = 0;
      if (rr < 4 || rr > 40) rr = 0;

      // HRV — standard deviation of RR intervals
      double hrv = 0;
      String stress = '';
      if (hrPeaks.length > 2) {
        final intervals = <double>[];
        for (int i = 1; i < hrPeaks.length; i++) {
          intervals.add((hrPeaks[i] - hrPeaks[i - 1]) / 30.0 * 1000);
        }
        final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
        final variance = intervals
            .map((i) => pow(i - avgInterval, 2))
            .reduce((a, b) => a + b) / intervals.length;
        hrv = sqrt(variance);

        if (hrv > 50) {
          stress = 'Low stress';
        } else if (hrv > 25) {
          stress = 'Moderate stress';
        } else {
          stress = 'High stress';
        }
      }

      setState(() {
        _heartRate = hr > 0 ? double.parse(hr.toStringAsFixed(1)) : null;
        _respiratoryRate = rr > 0 ? double.parse(rr.toStringAsFixed(1)) : null;
        _hrv = hrv > 0 ? double.parse(hrv.toStringAsFixed(1)) : null;
        _stressLevel = stress;
        _processing = false;
      });
    } catch (e) {
      setState(() => _processing = false);
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1917),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1917),
        foregroundColor: const Color(0xFFE8E4DE),
        title: const Text('Results'),
        automaticallyImplyLeading: false,
      ),
      body: _processing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFE8E4DE)),
                  SizedBox(height: 24),
                  Text(
                    'Analyzing PPG signal...',
                    style: TextStyle(color: Color(0xFFA8A29E)),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Your Results',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE8E4DE),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${widget.redValues.length} frames',
                        style: const TextStyle(
                            color: Color(0xFFA8A29E), fontSize: 13),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _signalQuality > 70
                              ? const Color(0xFF2E2A27)
                              : const Color(0xFF2E2A27),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _signalQuality > 70
                                ? const Color(0xFF8E8882)
                                : const Color(0xFF55504C),
                          ),
                        ),
                        child: Text(
                          'Signal: $_signalQuality%',
                          style: TextStyle(
                            color: _signalQuality > 70
                                ? const Color(0xFFD5D0C9)
                                : const Color(0xFF6B6661),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _ResultCard(
                    title: 'Heart Rate',
                    value: _heartRate != null
                        ? '${_heartRate!.toStringAsFixed(0)} BPM'
                        : 'Unable to detect',
                    subtitle: 'Normal: 60-100 BPM',
                    icon: Icons.favorite_outline,
                    isNormal: _heartRate != null &&
                        _heartRate! >= 60 &&
                        _heartRate! <= 100,
                    hasValue: _heartRate != null,
                  ),
                  const SizedBox(height: 12),
                  _ResultCard(
                    title: 'Respiratory Rate',
                    value: _respiratoryRate != null
                        ? '${_respiratoryRate!.toStringAsFixed(0)} breaths/min'
                        : 'Unable to detect',
                    subtitle: 'Normal: 12-20 breaths/min',
                    icon: Icons.air_outlined,
                    isNormal: _respiratoryRate != null &&
                        _respiratoryRate! >= 12 &&
                        _respiratoryRate! <= 20,
                    hasValue: _respiratoryRate != null,
                  ),
                  const SizedBox(height: 12),
                  _ResultCard(
                    title: 'HRV (Stress Indicator)',
                    value: _hrv != null
                        ? '${_hrv!.toStringAsFixed(0)} ms'
                        : 'Unable to detect',
                    subtitle: _stressLevel.isNotEmpty
                        ? _stressLevel
                        : 'Higher = more relaxed',
                    icon: Icons.psychology_outlined,
                    isNormal: _hrv != null && _hrv! > 25,
                    hasValue: _hrv != null,
                  ),
                  const SizedBox(height: 28),
                  if (_heartRate == null &&
                      _respiratoryRate == null &&
                      _hrv == null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF262320),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: const Color(0xFF34302D)),
                      ),
                      child: const Text(
                        'Signal too weak. Make sure your finger fully covers the camera and flash, and keep completely still.',
                        style: TextStyle(
                            color: Color(0xFFA8A29E), fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8E4DE),
                        foregroundColor: const Color(0xFF1C1917),
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Scan Again',
                          style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'Not a medical device — for screening only',
                      style: TextStyle(
                          color: Color(0xFF6B6661), fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final bool isNormal;
  final bool hasValue;

  const _ResultCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.isNormal,
    required this.hasValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF262320),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF34302D)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2E2A27),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                Icon(icon, color: const Color(0xFFE8E4DE), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFA8A29E),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFFE8E4DE),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF6B6661),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (hasValue)
            Icon(
              isNormal
                  ? Icons.check_circle_outline
                  : Icons.warning_outlined,
              color: isNormal
                  ? const Color(0xFFD5D0C9)
                  : const Color(0xFF9AA5B1),
              size: 24,
            ),
        ],
      ),
    );
  }
}