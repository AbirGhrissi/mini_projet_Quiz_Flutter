import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:camera/camera.dart';
import 'dart:async';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  late CameraController _cameraController;
  late FaceDetector _faceDetector;
  bool _isFaceDetected = false;
  bool _isCameraInitialized = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeFaceDetector();
    _initializeAnimationController();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.front);
      _cameraController = CameraController(frontCamera, ResolutionPreset.medium);
      await _cameraController.initialize();
      _cameraController.startImageStream(_processCameraImage);
      setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  void _initializeFaceDetector() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(enableContours: true, enableClassification: true),
    );
  }

  void _initializeAnimationController() {
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
  }

  Future<void> _processCameraImage(CameraImage image) async {
    try {
      final bytes = _extractBytesFromImage(image);
      final inputImage = _createInputImage(image, bytes);

      final faces = await _faceDetector.processImage(inputImage);
      setState(() {
        if (faces.isNotEmpty) {
          _isFaceDetected = true;
          _animationController.forward();
        } else {
          _isFaceDetected = false;
          _animationController.reset();
        }
      });

      if (_isFaceDetected) {
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
    }
  }

  Uint8List _extractBytesFromImage(CameraImage image) {
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  InputImage _createInputImage(CameraImage image, Uint8List bytes) {
    // Adjust for various formats
    InputImageRotation rotation = _cameraController.description.sensorOrientation == 90
        ? InputImageRotation.rotation90deg
        : InputImageRotation.rotation0deg;

    // Dynamically adjust format based on camera and image
    InputImageFormat format = _getImageFormat(image);

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  InputImageFormat _getImageFormat(CameraImage image) {
    // Vérifiez le format d'image en fonction de la version et de l'appareil
    switch (image.format) {
      case 35: // ImageFormat.yuv420_888
        return InputImageFormat.yuv_420_888;
      case 39: // ImageFormat.nv21
        return InputImageFormat.nv21;
      default:
      // Si un format non connu est trouvé, utiliser un format par défaut
        return InputImageFormat.nv21;
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _faceDetector.close();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_isCameraInitialized) CameraPreview(_cameraController),
          Positioned.fill(child: CustomPaint(painter: FaceDetectGuidePainter())),
          _buildCenterWidgets(),
        ],
      ),
    );
  }

  Widget _buildCenterWidgets() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildProgressIndicator(),
          const SizedBox(height: 30),
          _buildStatusMessage(),
          const SizedBox(height: 20),
          _buildTips(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: CircularProgressIndicator(
                value: _isFaceDetected ? 1.0 : 0.0,
                strokeWidth: 10,
                color: Colors.deepPurple,
                backgroundColor: Colors.grey.withOpacity(0.3),
              ),
            ),
            Text(
              '${(_isFaceDetected ? 100 : 0)}%',
              style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusMessage() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _isFaceDetected
          ? const Text(
        'Authentification réussie!',
        key: ValueKey('success'),
        style: TextStyle(fontSize: 24, color: Colors.green, fontWeight: FontWeight.bold),
      )
          : const Text(
        'Positionnez votre visage dans le cadre',
        key: ValueKey('scanning'),
        style: TextStyle(fontSize: 20, color: Colors.white),
      ),
    );
  }

  Widget _buildTips() {
    return AnimatedOpacity(
      opacity: _isFaceDetected ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          'Conseils :\n- Bien éclairer votre visage\n- Regarder droit vers la caméra\n- Maintenir une distance de 30-50cm',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ),
    );
  }
}

class FaceDetectGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2.5);
    final width = size.width * 0.6;
    final height = width * 1.2;

    final rect = Rect.fromCenter(center: center, width: width, height: height);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(20)), paint);

    final guidePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawLine(Offset(center.dx - width / 2, center.dy), Offset(center.dx + width / 2, center.dy), guidePaint);
    canvas.drawLine(Offset(center.dx, center.dy - height / 2), Offset(center.dx, center.dy + height / 2), guidePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
