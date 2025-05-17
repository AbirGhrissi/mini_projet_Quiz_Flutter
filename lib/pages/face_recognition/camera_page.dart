import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../model/user.dart';
import '../../utils/local_db.dart';
import '../../widgets/common_widgets.dart';
import '../home_page.dart';
import 'ml_service.dart';

class FaceScanScreen extends StatefulWidget {
  final User? user;
  final List<CameraDescription> cameras;

  const FaceScanScreen({
    Key? key,
    this.user,
    required this.cameras,
  }) : super(key: key);

  @override
  State<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen> {
  late CameraController _cameraController;
  late FaceDetector _faceDetector;
  final _mlService = MLService();
  final _nameController = TextEditingController();

  bool _isCameraReady = false;
  bool _isProcessing = false;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    _initializeEverything();
  }

  Future<void> _initializeEverything() async {
    try {
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
      );

      await _mlService.initialize();

      final frontCamera = widget.cameras.firstWhere(
            (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => widget.cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController.initialize();
      setState(() => _isCameraReady = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera initialization failed: $e')),
      );
    }
  }

  Future<void> _captureAndProcessFace() async {
    // Empêche plusieurs traitements simultanés ou si la caméra n'est pas prête
    if (_isProcessing || !_isCameraReady) return;
    setState(() => _isProcessing = true);

    try {
      // Capture une photo avec la caméra
      final image = await _cameraController.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);

      // Détecte les visages dans l'image capturée
      final faces = await _faceDetector.processImage(inputImage);

      // Convertit l'image en base64 pour le stockage
      final bytes = await File(image.path).readAsBytes();
      final base64Image = base64Encode(bytes);

      // Vérifie si un visage a été détecté
      if (faces.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No face detected. Please try again.')),
        );
        return;
      }

      // ----- Cas d'enregistrement (nouvel utilisateur) -----
      if (widget.user == null) {
        // Vérifie que le nom a été saisi
        if (_nameController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter your name')),
          );
          return;
        }

        // Sauvegarde les données du visage via MLService
        await _mlService.saveFaceData(File(image.path), _nameController.text);

        // Navigue vers la page d'accueil après l'enregistrement
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage(cameras: widget.cameras)),
        );
      }

      // ----- Cas de connexion (utilisateur existant) -----
      else {
        // Tente de reconnaître l'utilisateur
        final recognizedUser = await _mlService.predictFromFile(File(image.path));

        if (recognizedUser != null) {
          // Sauvegarde l'utilisateur reconnu localement
          await LocalDB.saveUser(recognizedUser);

          // Navigue vers la page d'accueil
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomePage(cameras: widget.cameras)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Face not recognized. Please try again.')),
          );
        }
      }
    } catch (e) {
      // Gestion des erreurs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      // Réactive l'interface après le traitement
      setState(() => _isProcessing = false);
    }
  }
  Future<void> _toggleFlash() async {
    if (!_isCameraReady) return;
    setState(() => _isFlashOn = !_isFlashOn);
    await _cameraController.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _faceDetector.close();
    _nameController.dispose();
    _mlService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isCameraReady
          ? Stack(
        children: [
          CameraPreview(_cameraController),
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.user == null)
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          fillColor: Colors.white,
                          filled: true,
                          hintText: 'Enter your name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: CWidgets.customExtendedButton(
                            text: _isProcessing ? "Processing..." : "Scan Face",
                            context: context,
                            isClickable: !_isProcessing,
                            onTap: _captureAndProcessFace,
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: Icon(
                            _isFlashOn ? Icons.flash_on : Icons.flash_off,
                            color: Colors.white,
                            size: 30,
                          ),
                          onPressed: _toggleFlash,
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}