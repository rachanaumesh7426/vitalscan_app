import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'results_screen.dart';

class PPGScreen extends StatefulWidget {
  const PPGScreen({super.key});

  @override
  State<PPGScreen> createState() => _PPGScreenState();
}

class _PPGScreenState extends State<PPGScreen> {
  CameraController? _controller;
  bool _isRecording = false;
  bool _isInitializing = true;
  int _countdown = 30;
  final List<double> _redValues = [];
  final List<double> _greenValues = [];

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    await Permission.camera.request();
    final cameras = await availableCameras();
    final rear = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
    );
    _controller = CameraController(
      rear,
      ResolutionPreset.low,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await _controller!.initialize();
    await _controller!.setFlashMode(FlashMode.torch);
    setState(() => _isInitializing = false);
  }

  Future<void> _startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _isRecording = true;
      _countdown = 30;
      _redValues.clear();
      _greenValues.clear();
    });

    // Start image stream to extract pixel values
    await _controller!.startImageStream((CameraImage image) {
      _processFrame(image);
    });

    // Countdown
    for (int i = 30; i > 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _countdown = i - 1);
    }

    // Stop recording
    await _controller!.stopImageStream();
    await _controller!.setFlashMode(FlashMode.off);

    setState(() => _isRecording = false);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultsScreen(
            redValues: _redValues,
            greenValues: _greenValues,
          ),
        ),
      );
    }
  }

void _processFrame(CameraImage image) {
  final yPlane = image.planes[0];
  final bytes = yPlane.bytes;
  
  double sum = 0;
  int count = 0;
  
  for (int i = 0; i < bytes.length; i += 10) {
    sum += bytes[i];
    count++;
  }
  
  final avgBrightness = sum / count;
  _redValues.add(avgBrightness);
  _greenValues.add(avgBrightness);
}

  @override
  void dispose() {
    _controller?.setFlashMode(FlashMode.off);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('PPG Scan'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isInitializing)
            const CircularProgressIndicator(color: Colors.white)
          else ...[
            Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: CameraPreview(_controller!),
                ),
              ),
            ),
            const SizedBox(height: 40),
            if (_isRecording) ...[
              Text(
                '$_countdown',
                style: const TextStyle(
                  fontSize: 80,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'seconds remaining',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                '${_redValues.length} frames captured',
                style: const TextStyle(
                    color: Colors.grey, fontSize: 12),
              ),
            ] else ...[
              const Text(
                'Place finger firmly\nover camera and flash',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              const SizedBox(height: 8),
              const Text(
                'Keep completely still for 30 seconds',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _startRecording,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Start Scan',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}