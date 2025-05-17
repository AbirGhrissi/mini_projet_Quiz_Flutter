import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as imglib;
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

import '../../model/user.dart';
import '../../utils/local_db.dart';
import '../../utils/utils.dart';
import 'image_converter.dart';

class MLService {
  Interpreter? _interpreter;
  List<double>? predictedArray;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      printIfDebug('Initializing MLService...');
      await _initializeInterpreter();
      _isInitialized = true;
      printIfDebug('MLService initialized.');
    } catch (e) {
      printIfDebug('MLService initialization failed: $e');
      rethrow;
    }
  }

  Future<User?> predict(
      CameraImage cameraImage,
      Face face,
      bool loginUser,
      String name,
      ) async {
    if (!_isInitialized || _interpreter == null) {
      throw Exception('MLService not initialized');
    }

    try {
      printIfDebug('Starting prediction...');
      final input = _preProcess(cameraImage, face);
      input.reshape([1, 112, 112, 3]);

      final output = List.generate(1, (index) => List.filled(192, 0.0));
      _interpreter!.run(input, output);
      output.reshape([192]);

      predictedArray = List<double>.from(output[0]);
      printIfDebug('Embedding calculated.');

      if (!loginUser) {
        final user = User(
          name: name,
          array: predictedArray!,
          imageBase64: '',
        );
        await LocalDB.saveUser(user);
        printIfDebug('User registered: $name');
        return null;
      } else {
        final user = LocalDB.getCurrentUser();
        if (user == null || user.array == null) {
          printIfDebug('No stored user found');
          return null;
        }

        final dist = euclideanDistance(predictedArray!, user.array!);
        const threshold = 1.5;
        printIfDebug('Distance: $dist');

        return dist <= threshold ? user : null;
      }
    } catch (e) {
      printIfDebug('Prediction error: $e');
      return null;
    }
  }

  Future<User?> predictFromFile(File imageFile) async {
    if (!_isInitialized || _interpreter == null) {
      throw Exception('MLService not initialized');
    }

    try {
      printIfDebug('Starting prediction from file...');

      // Vérification de la présence d'utilisateurs enregistrés
      final allUsers = LocalDB.getAllUsers();
      if (allUsers.isEmpty) {
        printIfDebug('No users registered in DB');
        return null;
      }

      // Traitement de l'image pour détecter les visages
      final inputImage = InputImage.fromFile(imageFile);
      final options = FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableLandmarks: false,
        enableContours: false,
      );
      final faceDetector = FaceDetector(options: options);
      final faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();

      if (faces.isEmpty) {
        printIfDebug('No face detected');
        return null;
      }

      final bytes = await imageFile.readAsBytes();
      final fullImage = imglib.decodeImage(bytes);
      if (fullImage == null) {
        printIfDebug('Failed to decode image');
        return null;
      }

      final face = faces.first;
      final rect = face.boundingBox;

      final croppedImage = imglib.copyCrop(
        fullImage,
        rect.left.toInt().clamp(0, fullImage.width - 1),
        rect.top.toInt().clamp(0, fullImage.height - 1),
        rect.width.toInt().clamp(1, fullImage.width),
        rect.height.toInt().clamp(1, fullImage.height),
      );

      final resizedImage = imglib.copyResizeCropSquare(croppedImage, 112);
      final input = _imageToByteListFloat32(resizedImage);
      input.reshape([1, 112, 112, 3]);

      final output = List.generate(1, (index) => List.filled(192, 0.0));
      _interpreter!.run(input, output);
      output.reshape([192]);

      predictedArray = List<double>.from(output[0]);

      // Comparer avec tous les utilisateurs enregistrés
      double minDist = double.infinity;
      User? closestUser;

      for (var user in allUsers) {
        if (user.array == null || user.array!.isEmpty) continue;

        final dist = euclideanDistance(predictedArray!, user.array!);
        printIfDebug('Distance with ${user.name}: $dist');

        if (dist < minDist) {
          minDist = dist;
          closestUser = user;
        }
      }

      const threshold = 1.5;
      printIfDebug('Min distance: $minDist, Threshold: $threshold');

      if (minDist <= threshold && closestUser != null) {
        printIfDebug('User recognized: ${closestUser.name}');
        await LocalDB.saveUser(closestUser); // Met à jour l'utilisateur courant
        return closestUser;
      } else {
        printIfDebug('No matching user found');
        return null;
      }
    } catch (e) {
      printIfDebug('Error in predictFromFile: $e');
      return null;
    }
  }

  Future<void> saveFaceData(File imageFile, String name) async {
    if (!_isInitialized || _interpreter == null) {
      throw Exception('MLService not initialized');
    }

    try {
      printIfDebug('Saving face data...');
      final bytes = await imageFile.readAsBytes();
      final inputImage = InputImage.fromFile(imageFile);
      final options = FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableLandmarks: false,
        enableContours: false,
      );
      final faceDetector = FaceDetector(options: options);
      final faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();

      if (faces.isEmpty) throw Exception('No face detected');

      final fullImage = imglib.decodeImage(bytes);
      if (fullImage == null) throw Exception('Image decoding failed');

      final face = faces.first;
      final rect = face.boundingBox;

      final croppedImage = imglib.copyCrop(
        fullImage,
        rect.left.toInt().clamp(0, fullImage.width - 1),
        rect.top.toInt().clamp(0, fullImage.height - 1),
        rect.width.toInt().clamp(1, fullImage.width),
        rect.height.toInt().clamp(1, fullImage.height),
      );

      final resizedImage = imglib.copyResizeCropSquare(croppedImage, 112);
      final input = _imageToByteListFloat32(resizedImage);
      input.reshape([1, 112, 112, 3]);

      final output = List.generate(1, (index) => List.filled(192, 0.0));
      _interpreter!.run(input, output);
      output.reshape([192]);

      predictedArray = List<double>.from(output[0]);
      final base64Img = base64Encode(bytes);
      final user = User(
        name: name,
        array: predictedArray!,
        imageBase64: base64Img,
      );

      await LocalDB.saveUser(user);
      printIfDebug('User saved: $name');
    } catch (e) {
      printIfDebug('Error saving face data: $e');
      rethrow;
    }
  }

  double euclideanDistance(List<double> l1, List<double> l2) {
    if (l1.length != l2.length) {
      throw ArgumentError('Les listes doivent avoir la même longueur');
    }

    double sum = 0;
    for (int i = 0; i < l1.length; i++) {
      sum += pow((l1[i] - l2[i]), 2);
    }
    return sqrt(sum);
  }

  Future<void> _initializeInterpreter() async {
    try {
      printIfDebug('Loading TFLite model...');
      _interpreter = await Interpreter.fromAsset('assets/mobilefacenet.tflite');
      printIfDebug('TFLite model loaded successfully.');
    } catch (e) {
      printIfDebug('Error loading TFLite model: $e');
      rethrow;
    }
  }

  List<List<List<List<double>>>> _preProcess(CameraImage image, Face faceDetected) {
    try {
      printIfDebug('Preprocessing image...');
      final croppedImage = _cropFace(image, faceDetected);
      final img = imglib.copyResizeCropSquare(croppedImage, 112);
      return _imageToByteListFloat32(img);
    } catch (e) {
      printIfDebug('Image preprocessing failed: $e');
      throw Exception('Image preprocessing error: $e');
    }
  }

  imglib.Image _cropFace(CameraImage image, Face faceDetected) {
    final convertedImage = _convertCameraImage(image);
    final x = max(0, faceDetected.boundingBox.left - 10.0);
    final y = max(0, faceDetected.boundingBox.top - 10.0);
    final w = min(
      convertedImage.width - x,
      faceDetected.boundingBox.width + 20.0,
    );
    final h = min(
      convertedImage.height - y,
      faceDetected.boundingBox.height + 20.0,
    );

    printIfDebug('Cropping face: x=$x, y=$y, w=$w, h=$h');

    return imglib.copyCrop(
      convertedImage,
      x.round(),
      y.round(),
      w.round(),
      h.round(),
    );
  }

  imglib.Image _convertCameraImage(CameraImage image) {
    final img = convertToImage(image);
    if (img == null) throw Exception('Image conversion failed');
    return imglib.copyRotate(img, -90);
  }

  List<List<List<List<double>>>> _imageToByteListFloat32(imglib.Image image) {
    final convertedBytes = List.generate(
        1,
            (_) => List.generate(
          112,
              (_) => List.generate(
            112,
                (_) => List<double>.filled(3, 0.0),
          ),
        ));

    for (var i = 0; i < 112; i++) {
      for (var j = 0; j < 112; j++) {
        final pixel = image.getPixel(j, i);
        convertedBytes[0][i][j][0] = (imglib.getRed(pixel) - 128) / 128;
        convertedBytes[0][i][j][1] = (imglib.getGreen(pixel) - 128) / 128;
        convertedBytes[0][i][j][2] = (imglib.getBlue(pixel) - 128) / 128;
      }
    }

    return convertedBytes;
  }

  void dispose() {
    printIfDebug('Disposing MLService...');
    _interpreter?.close();
    _isInitialized = false;
  }
}
