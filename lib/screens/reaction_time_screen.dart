import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

class ReactionTimeScreen extends StatefulWidget {
  const ReactionTimeScreen({super.key});

  @override
  State<ReactionTimeScreen> createState() => _ReactionTimeScreenState();
}

class _ReactionTimeScreenState extends State<ReactionTimeScreen> {
  static const int totalRounds = 10;
  
  int _round = 0;
  bool _waiting = false;
  bool _flashing = false;
  bool _tooEarly = false;
  bool _finished = false;
  DateTime? _flashTime;
  List<int> _reactionTimes = [];
  Timer? _timer;

  String get _interpretation {
    final avg = _average;
    if (avg < 200) return 'Excellent';
    if (avg < 250) return 'Good';
    if (avg < 300) return 'Average';
    if (avg < 400) return 'Slow';
    return 'Very slow';
  }

  String get _neurologicalNote {
    final avg = _average;
    if (avg < 250) return 'Normal neurological response';
    if (avg < 350) return 'Slightly elevated — may indicate fatigue';
    return 'Elevated — consider rest or medical check';
  }

  int get _average {
    if (_reactionTimes.isEmpty) return 0;
    return (_reactionTimes.reduce((a, b) => a + b) / _reactionTimes.length).round();
  }

  void _startRound() {
    if (_round >= totalRounds) return;

    setState(() {
      _waiting = true;
      _flashing = false;
      _tooEarly = false;
    });

    // Random delay 1.5 to 4 seconds
    final delay = 1500 + Random().nextInt(2500);
    _timer = Timer(Duration(milliseconds: delay), () {
      if (mounted) {
        setState(() {
          _flashing = true;
          _flashTime = DateTime.now();
        });

        // Auto advance if no tap after 2 seconds
        _timer = Timer(const Duration(seconds: 2), () {
          if (mounted && _flashing) {
            _reactionTimes.add(2000);
            _nextRound();
          }
        });
      }
    });
  }

  void _handleTap() {
    if (_finished) return;

    if (_flashing && _flashTime != null) {
      // Valid tap
      final reactionMs = DateTime.now().difference(_flashTime!).inMilliseconds;
      _reactionTimes.add(reactionMs);
      _timer?.cancel();
      _nextRound();
    } else if (_waiting) {
      // Too early
      _timer?.cancel();
      setState(() {
        _tooEarly = true;
        _waiting = false;
        _flashing = false;
      });
      // Restart round after 1 second
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _startRound();
      });
    }
  }

  void _nextRound() {
    setState(() {
      _round++;
      _flashing = false;
      _waiting = false;
    });

    if (_round >= totalRounds) {
      setState(() => _finished = true);
    } else {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _startRound();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _flashing
          ? const Color(0xFFF2EEE8)
          : const Color(0xFF1C1917),
      appBar: _finished || _round == 0
          ? AppBar(
              backgroundColor: const Color(0xFF1C1917),
              foregroundColor: const Color(0xFFE8E4DE),
              title: const Text('Reaction Time Test'),
            )
          : null,
      body: _finished ? _buildResults() : _buildTest(),
    );
  }

  Widget _buildTest() {
    return GestureDetector(
      onTap: _waiting || _flashing ? _handleTap : null,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_round == 0) ...[
              const Text(
                'Reaction Time Test',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE8E4DE),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Tap as fast as possible when the screen turns light.\n\n10 rounds total.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFA8A29E),
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _startRound,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8E4DE),
                  foregroundColor: const Color(0xFF1C1917),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Start Test',
                    style: TextStyle(fontSize: 18)),
              ),
            ] else if (_tooEarly) ...[
              const Icon(Icons.warning_outlined,
                  color: Color(0xFF9AA5B1), size: 64),
              const SizedBox(height: 16),
              const Text(
                'Too early!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE8E4DE),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Wait for the screen to flash',
                style: TextStyle(
                    color: Color(0xFFA8A29E), fontSize: 16),
              ),
            ] else if (_waiting) ...[
              Text(
                'Round ${_round + 1} of $totalRounds',
                style: const TextStyle(
                    color: Color(0xFF6B6661), fontSize: 14),
              ),
              const SizedBox(height: 40),
              const Text(
                'Get ready...',
                style: TextStyle(
                  fontSize: 32,
                  color: Color(0xFFE8E4DE),
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tap when screen flashes',
                style: TextStyle(
                    color: Color(0xFFA8A29E), fontSize: 16),
              ),
            ] else if (_flashing) ...[
              const Text(
                'TAP!',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1917),
                ),
              ),
            ] else ...[
              Text(
                _reactionTimes.isNotEmpty
                    ? '${_reactionTimes.last} ms'
                    : '',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE8E4DE),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$_round of $totalRounds done',
                style: const TextStyle(
                    color: Color(0xFFA8A29E), fontSize: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final best = _reactionTimes.reduce(min);
    final worst = _reactionTimes.reduce(max);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Reaction Time Results',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE8E4DE),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF262320),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF34302D)),
            ),
            child: Column(
              children: [
                Text(
                  '$_average ms',
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE8E4DE),
                  ),
                ),
                Text(
                  'Average reaction time',
                  style: const TextStyle(
                      color: Color(0xFFA8A29E), fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  _interpretation,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD5D0C9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF262320),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: const Color(0xFF34302D)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$best ms',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE8E4DE),
                        ),
                      ),
                      const Text('Best',
                          style: TextStyle(
                              color: Color(0xFFA8A29E),
                              fontSize: 13)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF262320),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: const Color(0xFF34302D)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$worst ms',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE8E4DE),
                        ),
                      ),
                      const Text('Worst',
                          style: TextStyle(
                              color: Color(0xFFA8A29E),
                              fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF262320),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF34302D)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: Color(0xFF9AA5B1), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _neurologicalNote,
                    style: const TextStyle(
                        color: Color(0xFFA8A29E), fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'All rounds (ms):',
            style: TextStyle(
                color: Color(0xFF6B6661), fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _reactionTimes.asMap().entries.map((e) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E2A27),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: const Color(0xFF34302D)),
                ),
                child: Text(
                  '${e.key + 1}: ${e.value}ms',
                  style: const TextStyle(
                      color: Color(0xFFE8E4DE), fontSize: 13),
                ),
              );
            }).toList(),
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