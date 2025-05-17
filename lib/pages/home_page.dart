import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../utils/local_db.dart';
import 'login_page.dart';

class HomePage extends StatelessWidget {
  final List<CameraDescription> cameras;

  const HomePage({Key? key, required this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = LocalDB.getCurrentUser();

    return Scaffold(
      appBar: AppBar(
        title: Text(currentUser?.name != null
            ? "Hi ${currentUser!.name} 👋"
            : "Welcome 👋"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (currentUser?.imageBase64 != null)
              CircleAvatar(
                radius: 50,
                backgroundImage: MemoryImage(
                  base64Decode(currentUser!.imageBase64!),
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              'You are successfully authenticated!',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  void _logout(BuildContext context) async {
    await LocalDB.logoutUser(); // n’efface pas les données
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => LoginPage(cameras: cameras),
      ),
    );
  }
}